unit Unit1;

interface

uses
  System.SysUtils,
  System.Types,
  System.UITypes,
  System.Classes,
  System.Variants,
  System.IOUtils,
  System.Math,
  System.Generics.Collections,
  FMX.Types,
  FMX.Controls,
  FMX.Forms,
  FMX.Graphics,
  FMX.Dialogs,
  FMX.StdCtrls,
  FMX.Objects,
  FMX.Layouts,
  FMX.Controls.Presentation,
  FMX.ListBox,
  FMX.Ani,
  FMX.Edit,
  FMX.Memo.Types,
  FMX.ScrollBox,
  FMX.Memo,
  {$IFDEF MSWINDOWS}
  Winapi.Windows,
  Winapi.ShlObj,
  Winapi.ActiveX,
  {$ENDIF}
  {$IFDEF ANDROID}
  Androidapi.JNI.App,
  Androidapi.JNI.Embarcadero,
  Androidapi.JNI.GraphicsContentViewText,
  Androidapi.JNI.Net,
  Androidapi.JNI.Os,
  Androidapi.JNI.Java,
  Androidapi.Helpers,
  Androidapi.JNI.DocumentsContract,
  FMX.Dialogs.Android,
  {$ENDIF}
  FMX.Platform,
  FMX.Effects,
  FMX.Filter.Effects,
  FMX.MultiView;

type
  TImageLoadThread = class(TThread)
  private
    FFilePath: string;
    FBitmap: TBitmap;
    FOnLoadComplete: TProc<TBitmap>;
  protected
    procedure Execute; override;
  public
    constructor Create(const AFilePath: string; AOnLoadComplete: TProc<TBitmap>);
    destructor Destroy; override;
  end;

  TForm1 = class(TForm)
    VertScrollBox: TVertScrollBox;
    ImgMain: TImage;
    LayoutControls: TGridLayout;
    BtnChooseFolder: TButton;
    BtnPlayPause: TButton;
    LabelDisplayTime: TLabel;
    TrackDelay: TTrackBar;
    LabelDelayValue: TLabel;
    LabelTransition: TLabel;
    CbTransition: TComboBox;
    LabelImageInfo: TLabel;
    LabelFolderPath: TLabel;
    TimerSlide: TTimer;
    ProgressBar: TProgressBar;
    LabelStatus: TLabel;
    ShadowEffect: TShadowEffect;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure BtnChooseFolderClick(Sender: TObject);
    procedure BtnPlayPauseClick(Sender: TObject);
    procedure TimerSlideTimer(Sender: TObject);
    procedure TrackDelayChange(Sender: TObject);
    procedure CbTransitionChange(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure ImgMainGesture(Sender: TObject; const EventInfo: TGestureEventInfo);
  private
    FFolder: string;
    FFiles: TStringList;
    FIndex: Integer;
    FPlaying: Boolean;
    FDelayMs: Integer;
    FTransition: string;
    FPlatform: string;
    FLoadThread: TImageLoadThread;
    FAnimatingOpacity: Boolean;
    procedure LoadImageFiles;
    procedure ShowImage(Index: Integer);
    procedure ApplyTransition(NewBitmap: TBitmap);
    procedure SetDelayFromTrack;
    procedure UpdateUILabels;
    procedure UpdateProgressBar;
    procedure LogMessage(const Msg: string);
    {$IFDEF ANDROID}
    procedure OpenFolderViaAndroidSAF;
    procedure HandleAndroidFolderSelection(const TreeUri: string);
    {$ENDIF}
    {$IFDEF MSWINDOWS}
    procedure OpenFolderViaWin64Dialog;
    {$ENDIF}
    procedure SafeLoadImage(const FilePath: string);
  public
    procedure AnimateFade(NewBitmap: TBitmap);
    procedure AnimateSlide(NewBitmap: TBitmap);
    procedure AnimateZoom(NewBitmap: TBitmap);
    procedure AnimateScale(NewBitmap: TBitmap);
  end;

var
  Form1: TForm1;

implementation

{$R *.fmx}

{ TImageLoadThread }

constructor TImageLoadThread.Create(const AFilePath: string; AOnLoadComplete: TProc<TBitmap>);
begin
  inherited Create(True);
  FFilePath := AFilePath;
  FOnLoadComplete := AOnLoadComplete;
  FBitmap := TBitmap.Create;
  FreeOnTerminate := True;
end;

destructor TImageLoadThread.Destroy;
begin
  FreeAndNil(FBitmap);
  inherited;
end;

procedure TImageLoadThread.Execute;
begin
  try
    FBitmap.LoadFromFile(FFilePath);
    TThread.Synchronize(nil, procedure
    begin
      if Assigned(FOnLoadComplete) then
        FOnLoadComplete(FBitmap);
    end);
  except
    // Silently handle errors
  end;
end;

{$IFDEF MSWINDOWS}
function SelectFolder(var Folder: string): Boolean;
var
  BrowseInfo: TBrowseInfo;
  ItemIDList: PItemIDList;
  DisplayName: array[0..MAX_PATH] of Char;
begin
  Result := False;
  FillChar(BrowseInfo, SizeOf(BrowseInfo), 0);
  with BrowseInfo do
  begin
    hwndOwner := 0;
    lpszTitle := 'Select a Folder with Images';
    ulFlags := BIF_RETURNONLYFSDIRS or BIF_NEWDIALOGSTYLE;
  end;

  ItemIDList := SHBrowseForFolder(BrowseInfo);
  if ItemIDList <> nil then
  begin
    if SHGetPathFromIDList(ItemIDList, DisplayName) then
    begin
      Folder := DisplayName;
      Result := True;
    end;
    CoTaskMemFree(ItemIDList);
  end;
end;
{$ENDIF}

procedure TForm1.FormCreate(Sender: TObject);
begin
  FFiles := TStringList.Create;
  FFiles.Sorted := True;
  FIndex := 0;
  FPlaying := False;
  FDelayMs := 5000;
  FTransition := 'Fade';
  FAnimatingOpacity := False;
  FLoadThread := nil;

  {$IFDEF MSWINDOWS}
  FPlatform := 'Windows 64-bit';
  {$ENDIF}
  {$IFDEF ANDROID}
  FPlatform := 'Android';
  {$ENDIF}

  TimerSlide.Enabled := False;
  TimerSlide.Interval := FDelayMs;

  // Setup Transition ComboBox
  CbTransition.Items.Clear;
  CbTransition.Items.Add('Fade');
  CbTransition.Items.Add('Slide');
  CbTransition.Items.Add('Zoom');
  CbTransition.Items.Add('Scale');
  CbTransition.Items.Add('None');
  CbTransition.ItemIndex := 0;

  // Setup TrackBar
  TrackDelay.Min := 1;
  TrackDelay.Max := 20;
  TrackDelay.Value := 5;

  // Image settings
  ImgMain.WrapMode := TImageWrapMode.Fit;
  ImgMain.Align := TAlignLayout.Client;

  // Progress bar setup
  ProgressBar.Max := 100;
  ProgressBar.Value := 0;
  ProgressBar.Visible := False;

  UpdateUILabels;
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  TimerSlide.Enabled := False;
  if Assigned(FLoadThread) then
  begin
    FLoadThread.Terminate;
    FLoadThread.WaitFor;
  end;
  FreeAndNil(FFiles);
end;

procedure TForm1.FormShow(Sender: TObject);
begin
  // Initial welcome message
  LogMessage('Welcome to Slideshow Viewer - ' + FPlatform);
end;

procedure TForm1.UpdateUILabels;
begin
  LabelDelayValue.Text := Format('%d second%s', [Round(TrackDelay.Value),
    IfThen(TrackDelay.Value > 1, 's', '')]);

  if FFiles.Count > 0 then
    LabelImageInfo.Text := Format('Image %d of %d | %s', [
      FIndex + 1,
      FFiles.Count,
      ExtractFileName(FFiles[FIndex])
    ])
  else
    LabelImageInfo.Text := 'No images loaded';

  if FFolder <> '' then
    LabelFolderPath.Text := '📁 ' + ExtractFileName(FFolder)
  else
    LabelFolderPath.Text := '📁 No folder selected';
end;

procedure TForm1.UpdateProgressBar;
var
  Progress: Integer;
begin
  if FFiles.Count > 0 then
  begin
    Progress := Round((FIndex / FFiles.Count) * 100);
    ProgressBar.Value := Progress;
  end;
end;

procedure TForm1.LogMessage(const Msg: string);
begin
  LabelStatus.Text := Msg;
end;

procedure TForm1.SetDelayFromTrack;
begin
  FDelayMs := Round(TrackDelay.Value * 1000);
  TimerSlide.Interval := FDelayMs;
  UpdateUILabels;
end;

procedure TForm1.TrackDelayChange(Sender: TObject);
begin
  SetDelayFromTrack;
end;

procedure TForm1.CbTransitionChange(Sender: TObject);
begin
  if CbTransition.ItemIndex >= 0 then
    FTransition := CbTransition.Items[CbTransition.ItemIndex];
end;

procedure TForm1.ImgMainGesture(Sender: TObject; const EventInfo: TGestureEventInfo);
begin
  if EventInfo.GestureID = igiLongPress then
  begin
    if FPlaying then
      BtnPlayPauseClick(nil);
  end;
end;

{$IFDEF MSWINDOWS}
procedure TForm1.OpenFolderViaWin64Dialog;
begin
  BtnChooseFolder.Enabled := False;
  ProgressBar.Visible := True;
  ProgressBar.Value := 0;
  LogMessage('Opening folder browser...');

  if SelectFolder(FFolder) then
  begin
    if TDirectory.Exists(FFolder) then
    begin
      LogMessage('Loading images...');
      TThread.CreateAnonymousThread(procedure
      begin
        LoadImageFiles;
        TThread.Synchronize(nil, procedure
        begin
          if FFiles.Count > 0 then
          begin
            FIndex := 0;
            ShowImage(0);
            LogMessage(Format('Successfully loaded %d image(s)', [FFiles.Count]));
          end
          else
            LogMessage('No images found in selected folder');
          UpdateUILabels;
          ProgressBar.Visible := False;
          BtnChooseFolder.Enabled := True;
        end);
      end).Start;
    end
    else
      LogMessage('Folder does not exist');
  end
  else
    LogMessage('No folder selected');

  BtnChooseFolder.Enabled := True;
end;
{$ENDIF}

{$IFDEF ANDROID}
procedure TForm1.OpenFolderViaAndroidSAF;
var
  Intent: JIntent;
begin
  BtnChooseFolder.Enabled := False;
  LogMessage('Opening folder picker...');

  try
    Intent := TJIntent.Create;
    Intent.setAction(StringToJString('android.intent.action.OPEN_DOCUMENT_TREE'));
    Intent.addFlags(TJIntent.JavaClass.FLAG_GRANT_READ_URI_PERMISSION);
    Intent.addFlags(TJIntent.JavaClass.FLAG_GRANT_PERSISTABLE_URI_PERMISSION);
    SharedActivity.startActivityForResult(Intent, 42);
  except
    on E: Exception do
      LogMessage('Error opening folder picker: ' + E.Message);
  end;

  BtnChooseFolder.Enabled := True;
end;

procedure TForm1.HandleAndroidFolderSelection(const TreeUri: string);
begin
  if TreeUri <> '' then
  begin
    FFolder := TreeUri;
    LogMessage('Loading images from selected folder...');
    TThread.CreateAnonymousThread(procedure
    begin
      LoadImageFiles;
      TThread.Synchronize(nil, procedure
      begin
        if FFiles.Count > 0 then
        begin
          FIndex := 0;
          ShowImage(0);
          LogMessage(Format('Successfully loaded %d image(s)', [FFiles.Count]));
        end
        else
          LogMessage('No images found in selected folder');
        UpdateUILabels;
      end);
    end).Start;
  end
  else
    LogMessage('Folder selection cancelled');
end;
{$ENDIF}

procedure TForm1.BtnChooseFolderClick(Sender: TObject);
begin
  FPlaying := False;
  TimerSlide.Enabled := False;
  BtnPlayPause.Text := 'Play';

  {$IFDEF MSWINDOWS}
  OpenFolderViaWin64Dialog;
  {$ENDIF}
  {$IFDEF ANDROID}
  OpenFolderViaAndroidSAF;
  {$ENDIF}
end;

procedure TForm1.LoadImageFiles;
var
  SR: TSearchRec;
  FileName: string;
  FilePath: string;
begin
  FFiles.Clear;

  if not TDirectory.Exists(FFolder) then
  begin
    LogMessage('Folder path does not exist');
    Exit;
  end;

  try
    if FindFirst(TPath.Combine(FFolder, '*.*'), faAnyFile, SR) = 0 then
    try
      repeat
        FilePath := TPath.Combine(FFolder, SR.Name);
        if not TDirectory.Exists(FilePath) then
        begin
          FileName := LowerCase(ExtractFileExt(FilePath));
          if (FileName = '.jpg') or (FileName = '.jpeg') or (FileName = '.png') or
             (FileName = '.bmp') or (FileName = '.gif') or (FileName = '.webp') then
            FFiles.Add(FilePath);
        end;
      until FindNext(SR) <> 0;
    finally
      FindClose(SR);
    end;
  except
    on E: Exception do
      LogMessage('Error loading images: ' + E.Message);
  end;
end;

procedure TForm1.BtnPlayPauseClick(Sender: TObject);
begin
  if FFiles.Count = 0 then
  begin
    LogMessage('Please choose a folder with images first');
    Exit;
  end;

  FPlaying := not FPlaying;
  TimerSlide.Enabled := FPlaying;
  BtnPlayPause.Text := IfThen(FPlaying, '⏸ Pause', '▶ Play');
  UpdateUILabels;
  LogMessage(IfThen(FPlaying, 'Slideshow started', 'Slideshow paused'));
end;

procedure TForm1.TimerSlideTimer(Sender: TObject);
begin
  if FFiles.Count = 0 then
    Exit;

  Inc(FIndex);
  if FIndex >= FFiles.Count then
    FIndex := 0;

  ShowImage(FIndex);
  UpdateUILabels;
  UpdateProgressBar;
end;

procedure TForm1.SafeLoadImage(const FilePath: string);
begin
  // Kill existing load thread if still running
  if Assigned(FLoadThread) then
  begin
    FLoadThread.Terminate;
    FLoadThread := nil;
  end;

  // Create new load thread
  FLoadThread := TImageLoadThread.Create(FilePath, procedure(Bitmap: TBitmap)
  begin
    if Assigned(Bitmap) and not Bitmap.IsEmpty then
    begin
      ApplyTransition(Bitmap);
    end;
  end);

  FLoadThread.Start;
end;

procedure TForm1.ShowImage(Index: Integer);
begin
  if (Index < 0) or (Index >= FFiles.Count) then
    Exit;

  SafeLoadImage(FFiles[Index]);
end;

procedure TForm1.ApplyTransition(NewBitmap: TBitmap);
begin
  case IndexText(FTransition, ['Fade', 'Slide', 'Zoom', 'Scale', 'None']) of
    0: AnimateFade(NewBitmap);
    1: AnimateSlide(NewBitmap);
    2: AnimateZoom(NewBitmap);
    3: AnimateScale(NewBitmap);
    4: ImgMain.Bitmap.Assign(NewBitmap);
  end;
end;

procedure TForm1.AnimateFade(NewBitmap: TBitmap);
var
  FadeOutAnim: TFloatAnimation;
begin
  if FAnimatingOpacity then
    Exit;

  FAnimatingOpacity := True;

  FadeOutAnim := TFloatAnimation.Create(nil);
  FadeOutAnim.Parent := ImgMain;
  FadeOutAnim.StartValue := 1.0;
  FadeOutAnim.StopValue := 0.0;
  FadeOutAnim.Duration := 0.25;
  FadeOutAnim.PropertyName := 'Opacity';
  FadeOutAnim.OnFinish := procedure(Sender: TObject)
  var
    FadeInAnim: TFloatAnimation;
  begin
    ImgMain.Bitmap.Assign(NewBitmap);
    ImgMain.Opacity := 0.0;

    FadeInAnim := TFloatAnimation.Create(nil);
    FadeInAnim.Parent := ImgMain;
    FadeInAnim.StartValue := 0.0;
    FadeInAnim.StopValue := 1.0;
    FadeInAnim.Duration := 0.25;
    FadeInAnim.PropertyName := 'Opacity';
    FadeInAnim.OnFinish := procedure(Sender: TObject)
    begin
      FAnimatingOpacity := False;
    end;
    FadeInAnim.Start;
  end;
  FadeOutAnim.Start;
end;

procedure TForm1.AnimateSlide(NewBitmap: TBitmap);
var
  SlideOutAnim: TFloatAnimation;
begin
  SlideOutAnim := TFloatAnimation.Create(nil);
  SlideOutAnim.Parent := ImgMain;
  SlideOutAnim.StartValue := 0;
  SlideOutAnim.StopValue := ImgMain.Width;
  SlideOutAnim.Duration := 0.35;
  SlideOutAnim.PropertyName := 'Position.X';
  SlideOutAnim.OnFinish := procedure(Sender: TObject)
  var
    SlideInAnim: TFloatAnimation;
  begin
    ImgMain.Bitmap.Assign(NewBitmap);
    ImgMain.Position.X := -ImgMain.Width;
    ImgMain.Opacity := 1.0;

    SlideInAnim := TFloatAnimation.Create(nil);
    SlideInAnim.Parent := ImgMain;
    SlideInAnim.StartValue := -ImgMain.Width;
    SlideInAnim.StopValue := 0;
    SlideInAnim.Duration := 0.35;
    SlideInAnim.PropertyName := 'Position.X';
    SlideInAnim.Start;
  end;
  SlideOutAnim.Start;
end;

procedure TForm1.AnimateZoom(NewBitmap: TBitmap);
var
  ZoomOutAnim: TFloatAnimation;
begin
  ZoomOutAnim := TFloatAnimation.Create(nil);
  ZoomOutAnim.Parent := ImgMain;
  ZoomOutAnim.StartValue := 1.0;
  ZoomOutAnim.StopValue := 0.7;
  ZoomOutAnim.Duration := 0.3;
  ZoomOutAnim.PropertyName := 'Scale.X';
  ZoomOutAnim.OnFinish := procedure(Sender: TObject)
  var
    ZoomInAnim: TFloatAnimation;
  begin
    ImgMain.Bitmap.Assign(NewBitmap);
    ImgMain.Scale.X := 0.7;
    ImgMain.Scale.Y := 0.7;
    ImgMain.Opacity := 1.0;

    ZoomInAnim := TFloatAnimation.Create(nil);
    ZoomInAnim.Parent := ImgMain;
    ZoomInAnim.StartValue := 0.7;
    ZoomInAnim.StopValue := 1.0;
    ZoomInAnim.Duration := 0.3;
    ZoomInAnim.PropertyName := 'Scale.X';
    TFloatAnimation.Create(nil).Parent := ImgMain;
    (ImgMain.ChildrenCount - 1);
    ZoomInAnim.Start;
  end;
  ZoomOutAnim.Start;
end;

procedure TForm1.AnimateScale(NewBitmap: TBitmap);
var
  ScaleOutAnim: TFloatAnimation;
begin
  ScaleOutAnim := TFloatAnimation.Create(nil);
  ScaleOutAnim.Parent := ImgMain;
  ScaleOutAnim.StartValue := 1.0;
  ScaleOutAnim.StopValue := 1.1;
  ScaleOutAnim.Duration := 0.4;
  ScaleOutAnim.PropertyName := 'Scale.X';
  ScaleOutAnim.OnFinish := procedure(Sender: TObject)
  var
    ScaleInAnim: TFloatAnimation;
  begin
    ImgMain.Bitmap.Assign(NewBitmap);
    ImgMain.Scale.X := 1.1;
    ImgMain.Scale.Y := 1.1;
    ImgMain.Opacity := 1.0;

    ScaleInAnim := TFloatAnimation.Create(nil);
    ScaleInAnim.Parent := ImgMain;
    ScaleInAnim.StartValue := 1.1;
    ScaleInAnim.StopValue := 1.0;
    ScaleInAnim.Duration := 0.4;
    ScaleInAnim.PropertyName := 'Scale.X';
    ScaleInAnim.Start;
  end;
  ScaleOutAnim.Start;
end;

end.

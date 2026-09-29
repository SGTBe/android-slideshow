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
  FMX.Platform;

type
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
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure BtnChooseFolderClick(Sender: TObject);
    procedure BtnPlayPauseClick(Sender: TObject);
    procedure TimerSlideTimer(Sender: TObject);
    procedure TrackDelayChange(Sender: TObject);
    procedure CbTransitionChange(Sender: TObject);
  private
    FFolder: string;
    FFiles: TStringList;
    FIndex: Integer;
    FPlaying: Boolean;
    FDelayMs: Integer;
    FTransition: string;
    FPlatform: string;
    procedure LoadImageFiles;
    procedure ShowImage(Index: Integer);
    procedure ApplyTransition(const NewFile: string);
    procedure SetDelayFromTrack;
    procedure UpdateUILabels;
    procedure LogMessage(const Msg: string);
    {$IFDEF ANDROID}
    procedure OpenFolderViaAndroidSAF;
    {$ENDIF}
    {$IFDEF MSWINDOWS}
    procedure OpenFolderViaWin64Dialog;
    {$ENDIF}
  public
    procedure AnimateFade(NewBitmap: TBitmap);
    procedure AnimateSlide(NewBitmap: TBitmap);
    procedure AnimateZoom(NewBitmap: TBitmap);
  end;

var
  Form1: TForm1;

implementation

{$R *.fmx}

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
  CbTransition.Items.Add('None');
  CbTransition.Items.Add('Fade');
  CbTransition.Items.Add('Slide');
  CbTransition.Items.Add('Zoom');
  CbTransition.ItemIndex := 1;

  // Setup TrackBar
  TrackDelay.Min := 1;
  TrackDelay.Max := 20;
  TrackDelay.Value := 5;

  // Image settings
  ImgMain.WrapMode := TImageWrapMode.Fit;

  UpdateUILabels;
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  TimerSlide.Enabled := False;
  FreeAndNil(FFiles);
end;

procedure TForm1.UpdateUILabels;
begin
  LabelDelayValue.Text := Format('%d seconds', [Round(TrackDelay.Value)]);
  if FFiles.Count > 0 then
    LabelImageInfo.Text := Format('Image %d of %d', [FIndex + 1, FFiles.Count])
  else
    LabelImageInfo.Text := 'No images loaded';

  if FFolder <> '' then
    LabelFolderPath.Text := 'Folder: ' + ExtractFileName(FFolder)
  else
    LabelFolderPath.Text := 'Folder: None selected';
end;

procedure TForm1.LogMessage(const Msg: string);
begin
  LabelImageInfo.Text := Msg;
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

{$IFDEF MSWINDOWS}
procedure TForm1.OpenFolderViaWin64Dialog;
begin
  if SelectFolder(FFolder) then
  begin
    if TDirectory.Exists(FFolder) then
    begin
      LoadImageFiles;
      if FFiles.Count > 0 then
      begin
        FIndex := 0;
        ShowImage(0);
        LogMessage(Format('Loaded %d images from folder', [FFiles.Count]));
      end
      else
        LogMessage('No images found in selected folder');
    end
    else
      LogMessage('Folder does not exist');
  end
  else
    LogMessage('No folder selected');

  UpdateUILabels;
end;
{$ENDIF}

{$IFDEF ANDROID}
procedure TForm1.OpenFolderViaAndroidSAF;
var
  Intent: JIntent;
begin
  Intent := TJIntent.Create;
  Intent.setAction(StringToJString('android.intent.action.OPEN_DOCUMENT_TREE'));
  SharedActivity.startActivityForResult(Intent, 42);
end;
{$ENDIF}

procedure TForm1.BtnChooseFolderClick(Sender: TObject);
begin
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
  BtnPlayPause.Text := IfThen(FPlaying, 'Pause', 'Play');
  UpdateUILabels;
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
end;

procedure TForm1.ShowImage(Index: Integer);
var
  FileName: string;
  NewBitmap: TBitmap;
begin
  if (Index < 0) or (Index >= FFiles.Count) then
    Exit;

  FileName := FFiles[Index];
  try
    NewBitmap := TBitmap.Create;
    try
      NewBitmap.LoadFromFile(FileName);
      ApplyTransition(NewBitmap);
    finally
      NewBitmap.Free;
    end;
  except
    on E: Exception do
      LogMessage('Error loading image: ' + E.Message);
  end;
end;

procedure TForm1.ApplyTransition(const NewFile: string);
var
  NewBitmap: TBitmap;
begin
  NewBitmap := TBitmap.Create;
  try
    NewBitmap.LoadFromFile(NewFile);
    ApplyTransition(NewBitmap);
  finally
    NewBitmap.Free;
  end;
end;

procedure TForm1.ApplyTransition(NewBitmap: TBitmap);
begin
  if FTransition = 'None' then
  begin
    ImgMain.Bitmap.Assign(NewBitmap);
  end
  else if FTransition = 'Fade' then
  begin
    AnimateFade(NewBitmap);
  end
  else if FTransition = 'Slide' then
  begin
    AnimateSlide(NewBitmap);
  end
  else if FTransition = 'Zoom' then
  begin
    AnimateZoom(NewBitmap);
  end;
end;

procedure TForm1.AnimateFade(NewBitmap: TBitmap);
var
  FadeOutAnim: TFloatAnimation;
  FadeInAnim: TFloatAnimation;
begin
  FadeOutAnim := TFloatAnimation.Create(nil);
  try
    FadeOutAnim.Parent := ImgMain;
    FadeOutAnim.StartValue := 1.0;
    FadeOutAnim.StopValue := 0.0;
    FadeOutAnim.Duration := 0.3;
    FadeOutAnim.PropertyName := 'Opacity';
    FadeOutAnim.OnFinish := procedure(Sender: TObject)
    begin
      ImgMain.Bitmap.Assign(NewBitmap);
      FadeInAnim := TFloatAnimation.Create(nil);
      try
        FadeInAnim.Parent := ImgMain;
        FadeInAnim.StartValue := 0.0;
        FadeInAnim.StopValue := 1.0;
        FadeInAnim.Duration := 0.3;
        FadeInAnim.PropertyName := 'Opacity';
        FadeInAnim.Start;
      except
        FadeInAnim.Free;
      end;
    end;
    FadeOutAnim.Start;
  except
    FadeOutAnim.Free;
  end;
end;

procedure TForm1.AnimateSlide(NewBitmap: TBitmap);
var
  SlideOutAnim: TFloatAnimation;
  SlideInAnim: TFloatAnimation;
begin
  SlideOutAnim := TFloatAnimation.Create(nil);
  try
    SlideOutAnim.Parent := ImgMain;
    SlideOutAnim.StartValue := 0;
    SlideOutAnim.StopValue := ImgMain.Width;
    SlideOutAnim.Duration := 0.4;
    SlideOutAnim.PropertyName := 'Position.X';
    SlideOutAnim.OnFinish := procedure(Sender: TObject)
    begin
      ImgMain.Bitmap.Assign(NewBitmap);
      ImgMain.Position.X := -ImgMain.Width;
      SlideInAnim := TFloatAnimation.Create(nil);
      try
        SlideInAnim.Parent := ImgMain;
        SlideInAnim.StartValue := -ImgMain.Width;
        SlideInAnim.StopValue := 0;
        SlideInAnim.Duration := 0.4;
        SlideInAnim.PropertyName := 'Position.X';
        SlideInAnim.Start;
      except
        SlideInAnim.Free;
      end;
    end;
    SlideOutAnim.Start;
  except
    SlideOutAnim.Free;
  end;
end;

procedure TForm1.AnimateZoom(NewBitmap: TBitmap);
var
  ZoomOutAnim: TFloatAnimation;
  ZoomInAnim: TFloatAnimation;
begin
  ZoomOutAnim := TFloatAnimation.Create(nil);
  try
    ZoomOutAnim.Parent := ImgMain;
    ZoomOutAnim.StartValue := 1.0;
    ZoomOutAnim.StopValue := 0.5;
    ZoomOutAnim.Duration := 0.3;
    ZoomOutAnim.PropertyName := 'Scale.X';
    ZoomOutAnim.OnFinish := procedure(Sender: TObject)
    begin
      ImgMain.Bitmap.Assign(NewBitmap);
      ImgMain.Scale.X := 0.5;
      ImgMain.Scale.Y := 0.5;
      ZoomInAnim := TFloatAnimation.Create(nil);
      try
        ZoomInAnim.Parent := ImgMain;
        ZoomInAnim.StartValue := 0.5;
        ZoomInAnim.StopValue := 1.0;
        ZoomInAnim.Duration := 0.3;
        ZoomInAnim.PropertyName := 'Scale.X';
        ZoomInAnim.Start;
      except
        ZoomInAnim.Free;
      end;
    end;
    ZoomOutAnim.Start;
  except
    ZoomOutAnim.Free;
  end;
end;

end.

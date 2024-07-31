unit UReportForm;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, Buttons,
  StdCtrls, fpspreadsheetgrid, DividerBevel, DateTimePicker, BCPanel,
  VirtualTrees,
  //DK packages utils
  DK_Vector, DK_VSTTypes, DK_Zoom, DK_StrUtils, DK_SheetExporter,
  //Project utils
  UDataBase, UUiUtils, UAppUtils, UTables, USheets;

type

  { TReportForm }

  TReportForm = class(TForm)
    BeginDatePicker: TDateTimePicker;
    BeginShiftComboBox: TComboBox;
    CaptionPanel: TBCPanel;
    DividerBevel1: TDividerBevel;
    DividerBevel2: TDividerBevel;
    DividerBevel3: TDividerBevel;
    EndDatePicker: TDateTimePicker;
    EndShiftComboBox: TComboBox;
    ExportButton: TSpeedButton;
    Label1: TLabel;
    LogPanel: TPanel;
    MainPanel: TPanel;
    PlaceCancelButton: TSpeedButton;
    PlaceEdit: TEdit;
    PlaceLabel: TLabel;
    PlacePanel: TPanel;
    PlaceSaveButton: TSpeedButton;
    ReportRadioButton: TRadioButton;
    MiddleLabel: TLabel;
    LogRadioButton: TRadioButton;
    SheetPanel: TPanel;
    Grid: TsWorksheetGrid;
    ViewPanel: TPanel;
    PeriodPanel: TPanel;
    Splitter1: TSplitter;
    StatisticMemo: TMemo;
    ToolPanel: TPanel;
    VT: TVirtualStringTree;
    ZoomBevel: TBevel;
    ZoomPanel: TPanel;
    procedure BeginDatePickerChange(Sender: TObject);
    procedure BeginShiftComboBoxChange(Sender: TObject);
    procedure EndDatePickerChange(Sender: TObject);
    procedure EndShiftComboBoxChange(Sender: TObject);
    procedure ExportButtonClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure LogRadioButtonClick(Sender: TObject);
    procedure PlaceCancelButtonClick(Sender: TObject);
    procedure PlaceEditChange(Sender: TObject);
    procedure PlaceSaveButtonClick(Sender: TObject);
    procedure ReportRadioButtonClick(Sender: TObject);
  private
    CanLogLoad: Boolean;

    MonthName, PlaceName: String;
    OldPlaceName: String;

    Log: TReportTable;

    ZoomPercent: Integer;
    Sheet: TReportSheet;

    LogIDs: TInt64Vector;
    LogManIDs, LogSectionCounts: TIntVector;
    LogDayDates, LogLocoNames, LogLocoNums, LogDepoNames: TSTrVector;
    LogTONames, LogAptNames, LogManNames, LogSubManNames: TSTrVector;

    procedure LogCreate;
    procedure LogLoad;

    procedure ReportDraw(const AZoomPercent: Integer);
    procedure ReportExport;
  public
    procedure ViewUpdate;
  end;

var
  ReportForm: TReportForm;

implementation

{$R *.lfm}

{ TReportForm }

procedure TReportForm.FormShow(Sender: TObject);
begin
  SetToolPanels([
    ToolPanel
  ]);
  SetToolButtons([
    ExportButton, PlaceSaveButton, PlaceCancelButton
  ]);
  SetCaptionPanels([
    CaptionPanel
  ]);
end;

procedure TReportForm.ViewUpdate;
begin
  LogLoad;
end;

procedure TReportForm.FormCreate(Sender: TObject);
begin
  CanLogLoad:= False;

  PlaceEdit.Text:= DataBase.SettingLoad('Подразделение');
  OldPlaceName:= PlaceEdit.Text;
  PlaceSaveButton.Visible:= False;
  PlaceCancelButton.Visible:= False;

  LogCreate;

  ZoomPercent:= 100;
  CreateZoomControls(50, 150, ZoomPercent, ZoomPanel, @ReportDraw, True);
  Sheet:= TReportSheet.Create(Grid.Worksheet, Grid);

  BeginDatePicker.Date:= Date;
  EndDatePicker.Date:= Date;

  CanLogLoad:= True;
end;

procedure TReportForm.FormDestroy(Sender: TObject);
begin
  FreeAndNil(Log);
  FreeAndNil(Sheet);
end;

procedure TReportForm.BeginDatePickerChange(Sender: TObject);
begin
  LogLoad;
end;

procedure TReportForm.BeginShiftComboBoxChange(Sender: TObject);
begin
  LogLoad;
end;

procedure TReportForm.EndDatePickerChange(Sender: TObject);
begin
  LogLoad;
end;

procedure TReportForm.EndShiftComboBoxChange(Sender: TObject);
begin
  LogLoad;
end;

procedure TReportForm.ExportButtonClick(Sender: TObject);
begin
  if ReportRadioButton.Checked then
    ReportExport
  else if LogRadioButton.Checked then
    Log.Save([ ctInteger, //№ п/п
              ctString,  //Дата
              ctString,  //Серия
              ctString,  //Номер
              ctString,  //Депо приписки
              ctString,  //Вид ТО
              ctInteger, //Количество секций
              ctString,  //Система АПТ
              ctString,  //Исполнитель
              ctString   //Замещающий
    ]);
end;

procedure TReportForm.LogRadioButtonClick(Sender: TObject);
begin
  SheetPanel.Visible:= False;
  SheetPanel.Align:= alBottom;
  VT.Align:= alClient;
  VT.Visible:= True;
end;

procedure TReportForm.ReportRadioButtonClick(Sender: TObject);
begin
  VT.Visible:= False;
  VT.Align:= alBottom;
  SheetPanel.Align:= alClient;
  SheetPanel.Visible:= True;
end;

procedure TReportForm.PlaceCancelButtonClick(Sender: TObject);
begin
  PlaceEdit.Text:= OldPlaceName;
  PlaceSaveButton.Visible:= False;
  PlaceCancelButton.Visible:= False;
end;

procedure TReportForm.PlaceEditChange(Sender: TObject);
begin
  PlaceSaveButton.Visible:= True;
  PlaceCancelButton.Visible:= True;
end;

procedure TReportForm.PlaceSaveButtonClick(Sender: TObject);
begin
  PlaceSaveButton.Visible:= False;
  PlaceCancelButton.Visible:= False;
  DataBase.SettingUpdate('Подразделение', PlaceEdit.Text);
  OldPlaceName:= PlaceEdit.Text;
  Sheet.PlaceNameDraw(STrim(PlaceEdit.Text));
end;

procedure TReportForm.LogCreate;
begin
  Log:= TReportTable.Create(VT);
  Log.CanSelect:= True;
  Log.HeaderFont.Style:= [fsBold];
  Log.Draw;
end;

procedure TReportForm.LogLoad;
var
  BD, ED: TDateTime;
  V: TStrVector;
begin
  if not CanLogLoad then Exit;

  LogIDs:= nil;
  Log.ValuesClear;
  StatisticMemo.Lines.Clear;

  MonthName:= FormatDateTime('mmmm yyyyг.', EndDatePicker.Date);
  PlaceName:= STrim(PlaceEdit.Text);

  BD:= CalcBeginDT(BeginDatePicker.Date, BeginShiftComboBox.ItemIndex);
  ED:= CalcEndDT(EndDatePicker.Date, EndShiftComboBox.ItemIndex);
  DataBase.LogListLoad(BD, ED, LogIDs, LogManIDs, LogSectionCounts,
                       LogDayDates, LogLocoNames, LogLocoNums, LogDepoNames,
                       LogTONames, LogAptNames, LogManNames, LogSubManNames);

  ReportDraw(ZoomPercent);
  if VIsNil(LogIDs) then Exit;

  Log.SetColumn('№ п/п', VIntToStr(VOrder(Length(LogIDs))));
  Log.SetColumn('Дата', LogDayDates);
  Log.SetColumn('Серия', LogLocoNames);
  Log.SetColumn('Номер', LogLocoNums);
  Log.SetColumn('Депо приписки', LogDepoNames);
  Log.SetColumn('Вид ТО', LogTONames);
  Log.SetColumn('Количество секций', VIntToStr(LogSectionCounts));
  Log.SetColumn('Система АПТ', LogAptNames);
  Log.SetColumn('Исполнитель', LogManNames);
  Log.SetColumn('Замещающий', LogSubManNames);
  Log.Draw;

  V:= Statistic(LogSectionCounts, LogTONames, LogManNames, LogSubManNames);
  VtoStrings(V, StatisticMemo.Lines);
end;

procedure TReportForm.ReportDraw(const AZoomPercent: Integer);
begin
  Grid.Visible:= False;
  Screen.Cursor:= crHourGlass;
  try
    ZoomPercent:= AZoomPercent;
    Sheet.Zoom(ZoomPercent);
    Sheet.Draw(MonthName, PlaceName, LogLocoNames, LogLocoNums, LogDepoNames,
               LogTONames, LogAptNames, LogManNames, LogSectionCounts);
  finally
    Grid.Visible:= True;
    Screen.Cursor:= crDefault;
  end;
end;

procedure TReportForm.ReportExport;
var
  Exporter: TSheetsExporter;
  Worksheet: TsWorksheet;
  ExpSheet: TReportSheet;
begin

  Exporter:= TSheetsExporter.Create;
  try
    Worksheet:= Exporter.AddWorksheet('Лист1');
    ExpSheet:= TReportSheet.Create(Worksheet, nil);
    try
      ExpSheet.Draw(MonthName, PlaceName, LogLocoNames, LogLocoNums, LogDepoNames,
                    LogTONames, LogAptNames, LogManNames, LogSectionCounts);
      //Exporter.PageSettings(spoLandscape);
      Exporter.Save('Выполнено!');
    finally
      FreeAndNil(ExpSheet);
    end;
  finally
    FreeAndNil(Exporter);
  end;
end;

end.


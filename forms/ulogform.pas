unit ULogForm;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  BCPanel, VirtualTrees, Buttons, DateTimePicker, LCLType, DateUtils,
  //DK packages utils
  DK_Vector, DK_StrUtils,
  //Project utils
  UDataBase, UUiUtils, UAppUtils, UTables;

type

  { TLogForm }

  TLogForm = class(TForm)
    EditingCaptionPanel: TBCPanel;
    EditingPanel: TPanel;
    EditingToolPanel: TPanel;
    LocoNumEdit: TEdit;
    LocoNumLabel: TLabel;
    LocoTypeComboBox: TComboBox;
    LocoTypeLabel: TLabel;
    LocoVT: TVirtualStringTree;
    LogAddButton: TSpeedButton;
    LogCancelButton: TSpeedButton;
    LogDelButton: TSpeedButton;
    LogCaptionPanel: TBCPanel;
    LogPanel: TPanel;
    LogVT: TVirtualStringTree;
    MainPanel: TPanel;
    ManComboBox: TComboBox;
    ManLabel: TLabel;
    StatisticMemo: TMemo;
    NextShiftButton: TSpeedButton;
    PrevShiftButton: TSpeedButton;
    ShiftComboBox: TComboBox;
    ShiftDatePicker: TDateTimePicker;
    ShiftLabel: TLabel;
    Splitter1: TSplitter;
    Splitter2: TSplitter;
    SubManComboBox: TComboBox;
    SubManLabel: TLabel;
    TOTypeComboBox: TComboBox;
    TOTypeLabel: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure LocoNumEditChange(Sender: TObject);
    procedure LocoNumEditKeyDown(Sender: TObject; var Key: Word;
      {%H-}Shift: TShiftState);
    procedure LocoVTNodeDblClick(Sender: TBaseVirtualTree;
      const {%H-}HitInfo: THitInfo);
    procedure LogAddButtonClick(Sender: TObject);
    procedure LogCancelButtonClick(Sender: TObject);
    procedure LogDelButtonClick(Sender: TObject);

    procedure PrevShiftButtonClick(Sender: TObject);
    procedure NextShiftButtonClick(Sender: TObject);
    procedure ShiftComboBoxChange(Sender: TObject);
    procedure ShiftDatePickerChange(Sender: TObject);
    procedure ShiftDatePickerCloseUp(Sender: TObject);
  private
    CanLogLoad: Boolean;

    LocoList: TLocoListForChooseTable;
    Log: TLogTable;

    ManIDs, SubManIDs, LocoTypeIDs, TOTypeIDs: TIntVector;

    LocoTypes, LocoNums, DepoNames, AptNames: TStrVector;
    LocoIDs, SectionCounts, IsCurrents, Sec1s, Sec2s, Sec3s: TIntVector;

    LogIDs: TInt64Vector;
    LogManIDs, LogSectionCounts: TIntVector;
    LogDayDates, LogLocoNames, LogLocoNums, LogDepoNames: TSTrVector;
    LogTONames, LogAptNames, LogManNames, LogSubManNames: TSTrVector;

    procedure LocoListCreate;
    procedure LocoListLoad;
    procedure LocoListSelect;
    procedure LocoListReturnDown;

    function ShiftDate: TDateTime;
    procedure ShiftPrev;
    procedure ShiftNext;

    procedure LogCreate;
    procedure LogLoad;
    procedure LogAdd;
    procedure LogDel;
    procedure LogCancel;
    procedure LogSelect;
  public
    procedure ViewUpdate;
  end;

var
  LogForm: TLogForm;

implementation

{$R *.lfm}

procedure TLogForm.FormCreate(Sender: TObject);
begin
  CanLogLoad:= False;

  LocoListCreate;
  LogCreate;
  DataBase.ManListLoad(ManComboBox, ManIDs);
  DataBase.SubManListLoad(SubManComboBox, SubManIDs);
  DataBase.LocoTypeListLoad(LocoTypeComboBox, LocoTypeIDs);
  DataBase.TOTypeListLoad(TOTypeComboBox, TOTypeIDs);
  ShiftDatePicker.Date:= Date;

  CanLogLoad:= True;
end;

procedure TLogForm.FormDestroy(Sender: TObject);
begin
  FreeAndNil(LocoList);
  FreeAndNil(Log);
end;

procedure TLogForm.FormShow(Sender: TObject);
begin
  SetToolPanels([
    EditingToolPanel
  ]);
  SetToolButtons([
    LogAddButton, LogCancelButton, LogDelButton
  ]);
  SetCaptionPanels([
    EditingCaptionPanel, LogCaptionPanel
  ]);
end;

procedure TLogForm.ViewUpdate;
begin
  LocoListLoad;
  LogLoad;
end;

procedure TLogForm.LocoNumEditChange(Sender: TObject);
begin
  LocoListLoad;
end;

procedure TLogForm.LocoNumEditKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if VIsNil(LocoIDs) or (Key<>VK_RETURN) then Exit;

  LocoList.Select(0);
  LocoVT.SetFocus;
end;

procedure TLogForm.LocoVTNodeDblClick(Sender: TBaseVirtualTree;
  const HitInfo: THitInfo);
begin
  LogAdd;
end;

procedure TLogForm.LogAddButtonClick(Sender: TObject);
begin
  LogAdd;
end;

procedure TLogForm.LogCancelButtonClick(Sender: TObject);
begin
  LogCancel;
end;

procedure TLogForm.LogDelButtonClick(Sender: TObject);
begin
  LogDel;
end;

procedure TLogForm.LocoListCreate;
begin
  LocoList:= TLocoListForChooseTable.Create(LocoVT);
  LocoList.OnSelect:= @LocoListSelect;
  LocoList.OnReturnKeyDown:= @LocoListReturnDown;
  //LocoList.SetSingleFont(MainForm.GridFont);
  LocoList.Draw;
end;

procedure TLogForm.LocoListLoad;
var
  LocoNum: String;
  TypeID: Integer;
  V: TStrVector;
begin
  LocoIDs:= nil;
  LocoList.ValuesClear;
  LocoNum:= STrim(LocoNumEdit.Text);
  LogCancelButton.Enabled:= not SEmpty(LocoNum);
  if SEmpty(LocoNum) then Exit;

  TypeID:= 0;
  if not VIsNil(LocoTypeIDs) then
    TypeID:= LocoTypeIDs[LocoTypeComboBox.ItemIndex];

  DataBase.LocoListLoad(LocoTypes, LocoNums, DepoNames, AptNames,
                        LocoIDs, SectionCounts, IsCurrents, Sec1s, Sec2s, Sec3s,
                        LocoNum, TypeID, 0, 0, 1 {current confug});

  if VIsNil(LocoIDs) then Exit;

  LocoList.SetVectors(IsCurrents, SectionCounts);

  LocoList.SetColumn('Серия', LocoTypes, taLeftJustify);
  LocoList.SetColumn('Номер', LocoNums);
  LocoList.SetColumn('Депо приписки', DepoNames);
  LocoList.SetColumn('Система АПТ', AptNames);

  V:= VIntToStr(Sec1s, True {empty zeros});
  VChangeIf(V, '1', '✓');
  LocoList.SetColumn('Секция №1', V);
  V:= VIntToStr(Sec2s, True {empty zeros});
  VChangeIf(V, '1', '✓');
  LocoList.SetColumn('Секция №2', V);
  V:= VIntToStr(Sec3s, True {empty zeros});
  VChangeIf(V, '1', '✓');
  LocoList.SetColumn('Прицепная', V);

  LocoList.Draw;
end;

procedure TLogForm.LocoListSelect;
begin
  LogAddButton.Enabled:= LocoList.IsSelected;
end;

procedure TLogForm.LocoListReturnDown;
begin
  LogAdd;
end;

function TLogForm.ShiftDate: TDateTime;
begin
  if ShiftComboBox.ItemIndex=0 then
    Result:= EncodeTime(9,0,0,0)
  else
    Result:= EncodeTime(21,0,0,0);
  Result:= Result + ShiftDatePicker.Date;
end;

procedure TLogForm.ShiftPrev;
var
  ThisIndex, NewIndex: Integer;
begin
  CanLogLoad:= False;
  ThisIndex:= ManComboBox.ItemIndex;
  if ShiftComboBox.ItemIndex=0 then {дневная}
  begin
    ShiftComboBox.ItemIndex:= 1;
    ShiftDatePicker.Date:= IncDay(ShiftDatePicker.Date, -1);
    NewIndex:= ThisIndex - 2;
    if NewIndex<0 then
      NewIndex:= 4 + NewIndex;
  end
  else begin {ночная}
    ShiftComboBox.ItemIndex:= 0;
    NewIndex:= (ThisIndex + 1) mod 4;
  end;
  ManComboBox.ItemIndex:= NewIndex;
  CanLogLoad:= True;
end;

procedure TLogForm.ShiftNext;
var
  ThisIndex, NewIndex: Integer;
begin
  CanLogLoad:= False;
  ThisIndex:= ManComboBox.ItemIndex;
  if ShiftComboBox.ItemIndex=0 then {дневная}
  begin
    ShiftComboBox.ItemIndex:= 1;
    NewIndex:= ThisIndex - 1; {в ночь придет предыдущая дневная смена}
    if NewIndex<0 then
      NewIndex:= 4 + NewIndex;
  end
  else begin {ночная}
    ShiftComboBox.ItemIndex:= 0;
    ShiftDatePicker.Date:= IncDay(ShiftDatePicker.Date, 1);
    NewIndex:= (ThisIndex + 2) mod 4;
  end;
  ManComboBox.ItemIndex:= NewIndex;
  CanLogLoad:= True;
end;

procedure TLogForm.LogCreate;
begin
  Log:= TLogTable.Create(LogVT);
  Log.CanSelect:= True;
  Log.OnSelect:= @LogSelect;
  Log.OnDelKeyDown:= @LogDel;
  //Log.HeaderFont.Style:= [fsBold];
  Log.Draw;
end;

procedure TLogForm.LogLoad;
var
  BD, ED: TDateTime;
  i: Integer;
  V: TStrVector;
begin
  if not CanLogLoad then Exit;

  LogIDs:= nil;
  Log.ValuesClear;
  StatisticMemo.Lines.Clear;

  LogCaptionPanel.Caption:= 'Журнал за ' + ShiftDateToStr(ShiftDate) + ' (' +
                            ShiftComboBox.Text + ' смена)';

  BD:= CalcBeginDT(ShiftDatePicker.Date, ShiftComboBox.ItemIndex);
  ED:= CalcEndDT(ShiftDatePicker.Date, ShiftComboBox.ItemIndex);
  DataBase.LogListLoad(BD, ED, LogIDs, LogManIDs, LogSectionCounts,
                       LogDayDates, LogLocoNames, LogLocoNums, LogDepoNames,
                       LogTONames, LogAptNames, LogManNames, LogSubManNames);

  if VIsNil(LogIDs) then Exit;

  i:= VIndexOf(ManIDs, VFirst(LogManIDs));
  if i>=0 then
    ManComboBox.ItemIndex:= i;

  Log.SetColumn('№ п/п', VIntToStr(VOrder(Length(LogIDs))));
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

procedure TLogForm.LogAdd;
var
  LocoID, TOTypeID, ManID, SubManID: Integer;
begin
  if not LocoList.IsSelected then Exit;

  LocoID:= LocoIDs[LocoList.SelectedIndex];
  TOTypeID:= TOTypeIDs[TOTypeComboBox.ItemIndex];
  ManID:= ManIDs[ManComboBox.ItemIndex];
  SubManID:= SubManIDs[SubManComboBox.ItemIndex];

  if not DataBase.LogAdd(ShiftDate, LocoID, TOTypeID, ManID, SubManID) then Exit;

  LogLoad;
  LogCancel;
end;

procedure TLogForm.LogDel;
begin
  if not Log.IsSelected then Exit;
  if not DataBase.LogDelete(LogIDs[Log.SelectedIndex]) then Exit;
  LogLoad;
end;

procedure TLogForm.LogCancel;
begin
  LocoNumEdit.Text:= EmptyStr;
  LocoNumEdit.SetFocus;
end;

procedure TLogForm.LogSelect;
begin
  LogDelButton.Enabled:= Log.IsSelected;
end;

procedure TLogForm.PrevShiftButtonClick(Sender: TObject);
begin
  ShiftPrev;
  LogLoad;
  LocoNumEdit.SetFocus;
end;

procedure TLogForm.NextShiftButtonClick(Sender: TObject);
begin
  ShiftNext;
  LogLoad;
  LocoNumEdit.SetFocus;
end;

procedure TLogForm.ShiftComboBoxChange(Sender: TObject);
begin
  LogLoad;
  LocoNumEdit.SetFocus;
end;

procedure TLogForm.ShiftDatePickerChange(Sender: TObject);
begin
  LogLoad;
end;

procedure TLogForm.ShiftDatePickerCloseUp(Sender: TObject);
begin
  LocoNumEdit.SetFocus;
end;

end.


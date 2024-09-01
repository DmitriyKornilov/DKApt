unit ULocoListForm;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, Buttons,
  StdCtrls, VirtualTrees, DividerBevel,
  //DK packages utils
  DK_CtrlUtils, DK_Vector, DK_VSTTables, DK_VSTTypes, DK_StrUtils, DK_Dialogs,
  //Project utils
  UDataBase, UUiUtils, UTables,
  //Forms
  ULocoEditForm;

type

  { TLocoListForm }

  TLocoListForm = class(TForm)
    AddButton: TSpeedButton;
    ConfigButton: TSpeedButton;
    ExportButton: TSpeedButton;
    DividerBevel2: TDividerBevel;
    FilterClearButton: TSpeedButton;
    ConfigComboBox: TComboBox;
    DepoComboBox: TComboBox;
    ConfigLabel: TLabel;
    AptComboBox: TComboBox;
    DepoLabel: TLabel;
    DelButton: TSpeedButton;
    AptLabel: TLabel;
    DividerBevel1: TDividerBevel;
    EditButton: TSpeedButton;
    FilterLabel: TLabel;
    FilterPanel: TPanel;
    LocoNumEdit: TEdit;
    LocoNumLabel: TLabel;
    LocoTypeComboBox: TComboBox;
    LocoTypeLabel: TLabel;
    VT: TVirtualStringTree;
    ToolPanel: TPanel;
    procedure AddButtonClick(Sender: TObject);
    procedure AptComboBoxChange(Sender: TObject);
    procedure ConfigButtonClick(Sender: TObject);
    procedure ConfigComboBoxChange(Sender: TObject);
    procedure DelButtonClick(Sender: TObject);
    procedure DepoComboBoxChange(Sender: TObject);
    procedure EditButtonClick(Sender: TObject);
    procedure ExportButtonClick(Sender: TObject);
    procedure FilterClearButtonClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure LocoNumEditChange(Sender: TObject);
    procedure LocoTypeComboBoxChange(Sender: TObject);
    procedure VTDblClick(Sender: TObject);
  private
    CanLoad: Boolean;

    TypeIDs, DepoIDs, AptIDs: TIntVector;
    LocoList: TLocoListForEditTable;

    LocoTypes, LocoNums, DepoNames, AptNames: TStrVector;
    LocoIDs, SectionCounts, IsCurrents, Sec1s, Sec2s, Sec3s: TIntVector;

    procedure LocoListCreate;
    procedure LocoListLoad(const ASelectedID: Integer = 0);
    procedure LocoListSelect;

    procedure FilterApply;
    procedure FilterClear;

    procedure LocoEditFormOpen(const AEditType: Byte); //0-добавить, 1-редактировать, 2-переконфигурировать
    procedure LocoDelete;
  public

  end;

var
  LocoListForm: TLocoListForm;

implementation

//uses UMainForm;

{$R *.lfm}

{ TLocoListForm }

procedure TLocoListForm.FormShow(Sender: TObject);
begin
  (Sender as TForm).Height:= Screen.Height - 200;
  (Sender as TForm).Width:= Screen.Width - 200;
  FormToScreenCenter(Sender as TForm);

  SetToolPanels([
    ToolPanel
  ]);
  SetToolButtons([
    AddButton, DelButton, EditButton, ConfigButton, ExportButton, FilterClearButton
  ]);

  CanLoad:= False;
  DataBase.LocoTypeListLoad(LocoTypeComboBox, TypeIDs);
  DataBase.DepoListLoad(DepoComboBox, DepoIDs);
  DataBase.AptListLoad(AptComboBox, AptIDs);
  CanLoad:= True;

  LocoListCreate;
  LocoListLoad;
end;

procedure TLocoListForm.LocoListCreate;
begin
  LocoList:= TLocoListForEditTable.Create(VT);
  LocoList.OnSelect:= @LocoListSelect;
  LocoList.OnDelKeyDown:= @LocoDelete;
  //LocoList.SetSingleFont(MainForm.GridFont);
  LocoList.Draw;
end;

procedure TLocoListForm.LocoListLoad(const ASelectedID: Integer = 0);
var
  LocoNum: String;
  i, SelectedLocoID, TypeID, DepoID, AptID, LocoConfig: Integer;
  V: TStrVector;
begin
  if not CanLoad then Exit;

  SelectedLocoID:= ASelectedID;
  if SelectedLocoID<=0 then
    if LocoList.IsSelected then
      SelectedLocoID:= LocoIDs[LocoList.SelectedIndex];

  LocoNum:= STrim(LocoNumEdit.Text);
  TypeID:= 0;
  if not VIsNil(TypeIDs) then
    TypeID:= TypeIDs[LocoTypeComboBox.ItemIndex];
  DepoID:= 0;
  if not VIsNil(DepoIDs) then
    DepoID:= DepoIDs[DepoComboBox.ItemIndex];
  AptID:= 0;
  if not VIsNil(AptIDs) then
    AptID:= AptIDs[AptComboBox.ItemIndex];
  LocoConfig:= ConfigComboBox.ItemIndex - 1;

  DataBase.LocoListLoad(LocoTypes, LocoNums, DepoNames, AptNames,
                        LocoIDs, SectionCounts, IsCurrents, Sec1s, Sec2s, Sec3s,
                        LocoNum, TypeID, DepoID, AptID, LocoConfig);

  LocoList.ValuesClear;
  if VIsNil(LocoIDs) then Exit;

  LocoList.SetVectors(IsCurrents, SectionCounts);

  LocoList.SetColumn('№ п/п', VIntToStr(VOrder(Length(LocoIDs))));
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
  V:= VIntToStr(IsCurrents);
  VChangeIf(V, '1', 'действующая');
  VChangeIf(V, '0', 'старая');
  LocoList.SetColumn('Конфигурация', V);

  LocoList.Draw;

  if SelectedLocoID=0 then Exit;
  i:= VIndexOf(LocoIDs, SelectedLocoID);
  if i>=0 then
    LocoList.Select(i);
end;

procedure TLocoListForm.LocoListSelect;
begin
  DelButton.Enabled:= LocoList.IsSelected;
  EditButton.Enabled:= DelButton.Enabled;
  ConfigButton.Enabled:= DelButton.Enabled and (IsCurrents[LocoList.SelectedIndex]=1);
end;

procedure TLocoListForm.FilterApply;
begin
  FilterClearButton.Visible:= CanLoad;
  LocoListLoad;
end;

procedure TLocoListForm.FilterClear;
begin
  FilterClearButton.Visible:= False;
  CanLoad:= False;
  LocoTypeComboBox.ItemIndex:= 0;
  LocoNumEdit.Text:= EmptyStr;
  ConfigComboBox.ItemIndex:= 2;
  DepoComboBox.ItemIndex:= 0;
  AptComboBox.ItemIndex:= 0;
  CanLoad:= True;
  LocoListLoad;
end;

procedure TLocoListForm.LocoEditFormOpen(const AEditType: Byte);
var
  LocoEditForm: TLocoEditForm;
  LocoID: Integer;
begin
  LocoEditForm:= TLocoEditForm.Create(nil);
  try
    if AEditType=0 then //добавить
      LocoID:= 0
    else
      LocoID:= LocoIDs[LocoList.SelectedIndex];
    LocoEditForm.EditType:= AEditType;
    LocoEditForm.LocoID:= LocoID;
    if LocoEditForm.ShowModal=mrOK then
    begin
      LocoID:= LocoEditForm.LocoID;
      LocoListLoad(LocoID);
    end;
  finally
    FreeAndNil(LocoEditForm);
  end;
end;

procedure TLocoListForm.LocoDelete;
begin
  if not LocoList.IsSelected then Exit;
  if not Confirm('Внимание! Будут удалены из отчетов все записи об этом локомотиве! ' +
                 'Удалить?') then Exit;
  DataBase.LocoDelete(LocoIDs[LocoList.SelectedIndex]);
  LocoListLoad;
end;

procedure TLocoListForm.FormDestroy(Sender: TObject);
begin
  FreeAndNil(LocoList);
end;

procedure TLocoListForm.FilterClearButtonClick(Sender: TObject);
begin
  FilterClear;
end;

procedure TLocoListForm.LocoTypeComboBoxChange(Sender: TObject);
begin
  FilterApply;
end;

procedure TLocoListForm.VTDblClick(Sender: TObject);
begin
  if not LocoList.IsSelected then Exit;
  LocoEditFormOpen(1);
end;

procedure TLocoListForm.LocoNumEditChange(Sender: TObject);
begin
  FilterApply;
end;

procedure TLocoListForm.ConfigComboBoxChange(Sender: TObject);
begin
  FilterApply;
end;

procedure TLocoListForm.DelButtonClick(Sender: TObject);
begin
  LocoDelete;
end;

procedure TLocoListForm.DepoComboBoxChange(Sender: TObject);
begin
  FilterApply;
end;

procedure TLocoListForm.AptComboBoxChange(Sender: TObject);
begin
  FilterApply;
end;

procedure TLocoListForm.AddButtonClick(Sender: TObject);
begin
  LocoEditFormOpen(0);
end;

procedure TLocoListForm.EditButtonClick(Sender: TObject);
begin
  LocoEditFormOpen(1);
end;

procedure TLocoListForm.ConfigButtonClick(Sender: TObject);
begin
  LocoEditFormOpen(2);
end;

procedure TLocoListForm.ExportButtonClick(Sender: TObject);
begin
  LocoList.Save([ ctInteger, //№ п/п
                  ctString,  //Серия
                  ctString,  //Номер
                  ctString,  //Депо приписки
                  ctString,  //Система АПТ
                  ctString,  //Секция №1
                  ctString,  //Секция №2
                  ctString,  //Прицепная
                  ctString   //Конфигурация
  ]);

end;

end.


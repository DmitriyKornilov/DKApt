unit ULocoEditForm;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, Buttons,
  StdCtrls,
  //DK packages utils
  DK_StrUtils, DK_Dialogs, DK_Vector,
  //Project utils
  UDataBase, UImages;

type

  { TLocoEditForm }

  TLocoEditForm = class(TForm)
    ButtonPanel: TPanel;
    ButtonPanelBevel: TBevel;
    CancelButton: TSpeedButton;
    Sec1CheckBox: TCheckBox;
    Sec2CheckBox: TCheckBox;
    Sec3CheckBox: TCheckBox;
    DepoComboBox: TComboBox;
    LocoTypeComboBox: TComboBox;
    AptComboBox: TComboBox;
    LocoNumEdit: TEdit;
    LocoTypeLabel: TLabel;
    AptLabel: TLabel;
    LocoNumLabel: TLabel;
    SecLabel: TLabel;
    DepoLabel: TLabel;
    SaveButton: TSpeedButton;
    procedure FormShow(Sender: TObject);
    procedure LocoTypeComboBoxChange(Sender: TObject);
    procedure SaveButtonClick(Sender: TObject);
    procedure CancelButtonClick(Sender: TObject);
  private
    TypeIDs, DepoIDs, AptIDs, SectionCounts: TIntVector;
    procedure SetVisibles;
    procedure LocoLoad;
  public
    EditType: Byte;
    LocoID: Integer;
  end;

var
  LocoEditForm: TLocoEditForm;

implementation

{$R *.lfm}

{ TLocoEditForm }

procedure TLocoEditForm.FormShow(Sender: TObject);
begin
  Images.ToButtons([SaveButton, CancelButton]);
  Constraints.MinHeight:= Height;
  Constraints.MinWidth:= Width;

  case EditType of
  0: Caption:= Caption + ' (добавление нового)';
  1: Caption:= Caption + ' (редактирование)';
  2: Caption:= Caption + ' (изменение конфигурации)';
  end;

  DataBase.LocoTypeListLoad(LocoTypeComboBox, TypeIDs, False);
  DataBase.SectionCountListLoad(SectionCounts);
  DataBase.DepoListLoad(DepoComboBox, DepoIDs, False);
  DataBase.AptListLoad(AptComboBox, AptIDs, False);
  SetVisibles;

  LocoLoad;
end;

procedure TLocoEditForm.LocoTypeComboBoxChange(Sender: TObject);
begin
  SetVisibles;
end;

procedure TLocoEditForm.SaveButtonClick(Sender: TObject);
var
  IsOK: Boolean;
  LocoNum: String;
  TypeID, DepoID, AptID, Sec1, Sec2, Sec3: Integer;
begin
  IsOK:= False;

  if SEmpty(LocoTypeComboBox.Text) then
  begin
    ShowInfo('Не указана серия локомотива!');
    Exit;
  end;

  LocoNum:= STrim(LocoNumEdit.Text);
  if SEmpty(LocoNum) then
  begin
    ShowInfo('Не указан номер локомотива!');
    Exit;
  end;

  if SEmpty(DepoComboBox.Text) then
  begin
    ShowInfo('Не указано депо приписки локомотива!');
    Exit;
  end;

  if SEmpty(AptComboBox.Text) then
  begin
    ShowInfo('Не указан тип системы АПТ!');
    Exit;
  end;

  TypeID:= TypeIDs[LocoTypeComboBox.ItemIndex];
  DepoID:= DepoIDs[DepoComboBox.ItemIndex];
  AptID:= AptIDs[AptComboBox.ItemIndex];

  Sec1:= Ord(Sec1CheckBox.Checked);
  Sec2:= Ord(Sec2CheckBox.Checked);
  Sec3:= Ord(Sec3CheckBox.Checked);

  case EditType of
  0: IsOK:= DataBase.LocoAdd(LocoID, LocoNum, TypeID, DepoID, AptID, Sec1, Sec2, Sec3);
  1: IsOK:= DataBase.LocoUpdate(LocoID, LocoNum, TypeID, DepoID, AptID, Sec1, Sec2, Sec3);
  2: IsOK:= DataBase.LocoReconfig(LocoID, LocoNum, TypeID, DepoID, AptID, Sec1, Sec2, Sec3);
  end;

  if not IsOK then Exit;
  ModalResult:= mrOK;
end;

procedure TLocoEditForm.CancelButtonClick(Sender: TObject);
begin
  ModalResult:= mrCancel;
end;

procedure TLocoEditForm.SetVisibles;
var
  n: Integer;
begin
  if VIsNil(SectionCounts) then Exit;
  n:= SectionCounts[LocoTypeComboBox.ItemIndex];
  Sec2CheckBox.Visible:= n>1;
  Sec2CheckBox.Checked:= Sec2CheckBox.Visible;
  Sec3CheckBox.Visible:= n>2;
  Sec2CheckBox.Checked:= Sec2CheckBox.Visible;
end;

procedure TLocoEditForm.LocoLoad;
var
  LocoNum: String;
  i, TypeID, DepoID, AptID, Sec1, Sec2, Sec3: Integer;
begin
  if LocoID<=0 then Exit;
  if not DataBase.LocoLoad(LocoID, LocoNum, TypeID, DepoID, AptID, Sec1, Sec2, Sec3) then Exit;

  i:= VIndexOf(TypeIDs, TypeID);
  if i>=0 then
    LocoTypeComboBox.ItemIndex:= i;

  LocoNumEdit.Text:= LocoNum;

  i:= VIndexOf(DepoIDs, DepoID);
  if i>=0 then
    DepoComboBox.ItemIndex:= i;

  i:= VIndexOf(AptIDs, AptID);
  if i>=0 then
    AptComboBox.ItemIndex:= i;

  SetVisibles;

  Sec1CheckBox.Checked:= Sec1=1;
  Sec2CheckBox.Checked:= Sec2CheckBox.Visible and (Sec2=1);
  Sec3CheckBox.Checked:= Sec3CheckBox.Visible and (Sec3=1);

end;

end.


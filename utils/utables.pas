unit UTables;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Graphics, VirtualTrees,
  //DK packages utils
  DK_Vector, DK_VSTTables;

type

  { TLocoListCustomTable }

  TLocoListCustomTable = class (TVSTTable)
  private
    FIsCurrents, FSectionCounts: TIntVector;
  protected
    procedure CellFont(Node: PVirtualNode; {%H-}Column: TColumnIndex); override;
    function CellBGColor(Node: PVirtualNode; {%H-}Column: TColumnIndex): TColor; override;
  public
    procedure SetVectors(const AIsCurrents, ASectionCounts: TIntVector);
  end;

  { TLocoListForEditTable }

  TLocoListForEditTable = class (TLocoListCustomTable)
  public
    constructor Create(const ATree: TVirtualStringTree);
  end;

  { TLocoListForChooseTable }

  TLocoListForChooseTable = class (TLocoListCustomTable)
  public
    constructor Create(const ATree: TVirtualStringTree);
  end;

  { TLogTable }

  TLogTable = class (TVSTTable)
  public
    constructor Create(const ATree: TVirtualStringTree);
  end;

  { TReportTable }

  TReportTable = class (TVSTTable)
  public
    constructor Create(const ATree: TVirtualStringTree);
  end;

implementation

{ TLocoListCustomTable }

procedure TLocoListCustomTable.CellFont(Node: PVirtualNode; Column: TColumnIndex);
begin
  inherited CellFont(Node, Column);
  if FIsCurrents[Node^.Index]=0 then
    FCellFont.Color:= clGrayText;
end;

function TLocoListCustomTable.CellBGColor(Node: PVirtualNode; Column: TColumnIndex): TColor;
begin
  Result:= inherited CellBGColor(Node, Column);

  if (FHeaderCaptions[Column]= 'Секция №2') and (FSectionCounts[Node^.Index]<2) then
    Result:= clSilver;
  if (FHeaderCaptions[Column]= 'Прицепная') and (FSectionCounts[Node^.Index]<3) then
    Result:= clSilver;
end;

procedure TLocoListCustomTable.SetVectors(const AIsCurrents, ASectionCounts: TIntVector);
begin
  FIsCurrents:= AIsCurrents;
  FSectionCounts:= ASectionCounts;
end;

{ TLocoListForEditTable }

constructor TLocoListForEditTable.Create(const ATree: TVirtualStringTree);
begin
  inherited Create(ATree);
  CanSelect:= True;
  HeaderFont.Style:= [fsBold];
  AddColumn('№ п/п', 60);
  AddColumn('Серия', 150);
  AddColumn('Номер', 150);
  AddColumn('Депо приписки', 200);
  AddColumn('Система АПТ', 200);
  AddColumn('Секция №1', 100);
  AddColumn('Секция №2', 100);
  AddColumn('Прицепная', 100);
  AddColumn('Конфигурация', 150);
  AutosizeColumnDisable;
end;

{ TLocoListForChooseTable }

constructor TLocoListForChooseTable.Create(const ATree: TVirtualStringTree);
begin
  inherited Create(ATree);
  CanSelect:= True;
  CanUnselect:= False;
  //HeaderFont.Style:= [fsBold];
  AddColumn('Серия', 150);
  AddColumn('Номер', 150);
  AddColumn('Депо приписки', 200);
  AddColumn('Система АПТ', 200);
  AddColumn('Секция №1', 100);
  AddColumn('Секция №2', 100);
  AddColumn('Прицепная', 100);
  AutosizeColumnDisable;
end;

{ TLogTable }

constructor TLogTable.Create(const ATree: TVirtualStringTree);
begin
  inherited Create(ATree);
  HeaderFont.Style:= [fsBold];
  AddColumn('№ п/п', 60);
  //AddColumn('Дата', 150);
  AddColumn('Серия', 150);
  AddColumn('Номер', 150);
  AddColumn('Депо приписки', 200);
  AddColumn('Вид ТО', 100);
  AddColumn('Количество секций', 150);
  AddColumn('Система АПТ', 200);
  AddColumn('Исполнитель', 150);
  AddColumn('Замещающий', 150);
  AutosizeColumnDisable;
end;

{ TReportTable }

constructor TReportTable.Create(const ATree: TVirtualStringTree);
begin
  inherited Create(ATree);
  HeaderFont.Style:= [fsBold];
  AddColumn('№ п/п', 60);
  AddColumn('Дата', 150);
  AddColumn('Серия', 150);
  AddColumn('Номер', 120);
  AddColumn('Депо приписки', 200);
  AddColumn('Вид ТО', 100);
  AddColumn('Количество секций', 150);
  AddColumn('Система АПТ', 190);
  AddColumn('Исполнитель', 150);
  AddColumn('Замещающий', 150);
  AutosizeColumnDisable;
end;

end.


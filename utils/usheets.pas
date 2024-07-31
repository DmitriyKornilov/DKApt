unit USheets;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Graphics, fpspreadsheetgrid, fpspreadsheet,
  //DK packages utils
  DK_SheetTypes, DK_Fonts, DK_Vector;

type

  { TReportSheet }

  TReportSheet = class(TCustomSheet)
  private
    const
      COL_WIDTHS: array of Integer = (
        65,  //№ п/п
        110, //Наименование системы
        110, //Серия локомотива
        110, //Номер локомотива
        140, //Депо приписки
        110, //Наименование работ
        130, //Количество выполненных работ (в секциях)
        140  //Фамилия исполнителя
      );
      TITLE_HEIGHT = 50;
      ROWS_HEIGHT = 20;
    procedure CaptionDraw(const AMonthName, APlaceName: String);
  protected
    function SetWidths: TIntVector; override;
  public
    constructor Create(const AWorksheet: TsWorksheet; const AGrid: TsWorksheetGrid);
    procedure Draw(const AMonthName, APlaceName: String;
                   const ALocoNames, ALocoNums, ADepoNames, ATONames, AAptNames, AManNames: TStrVector;
                   const ASectionCounts: TIntVector);
    procedure PlaceNameDraw(const APlaceName: String);
  end;

implementation

{ TReportSheet }

procedure TReportSheet.CaptionDraw(const AMonthName, APlaceName: String);
var
  R: Integer;
begin
  Writer.SetFont(Font.Name, Font.Size+4, [fsBold], clBlack);
  Writer.SetAlignment(haCenter, vaCenter);

  R:= 1;
  Writer.WriteText(R, 1, R, Writer.ColCount, 'ОТЧЕТ по системам пожаротушения');

  R:= R+2;
  Writer.SetFont(Font.Name, Font.Size+2, [fsBold], clBlack);
  Writer.SetAlignment(haRight, vaCenter);
  Writer.WriteText(R, 2, 'Месяц');
  Writer.WriteText(R, 6, 'Депо');
  Writer.SetAlignment(haLeft, vaCenter);
  Writer.SetFont(Font.Name, Font.Size+2, [fsUnderline], clBlack);
  Writer.WriteText(R, 3, R, 4, AMonthName);
  PlaceNameDraw(APlaceName);

  R:= R+3;
  Writer.SetFont(Font.Name, Font.Size, [fsBold], clBlack);
  Writer.SetAlignment(haCenter, vaCenter);
  Writer.WriteText(R, 1, '№ п/п', cbtOuter);
  Writer.WriteText(R, 2, 'Наименование системы', cbtOuter);
  Writer.WriteText(R, 3, 'Серия локомотива', cbtOuter);
  Writer.WriteText(R, 4, 'Номер локомотива', cbtOuter);
  Writer.WriteText(R, 5, 'Депо приписки локомотива', cbtOuter);
  Writer.WriteText(R, 6, 'Наименование работ', cbtOuter);
  Writer.WriteText(R, 7, 'Количество выполненных работ (в секциях)', cbtOuter);
  Writer.WriteText(R, 8, 'Фамилия исполнителя', cbtOuter);

  Writer.SetRowHeight(R, TITLE_HEIGHT);
end;

procedure TReportSheet.PlaceNameDraw(const APlaceName: String);
begin
  Writer.SetAlignment(haLeft, vaCenter);
  Writer.SetFont(Font.Name, Font.Size+2, [{fsUnderline}], clBlack);
  Writer.WriteText(3, 7, 3, Writer.ColCount, APlaceName);
end;

function TReportSheet.SetWidths: TIntVector;
begin
  Result:= VCreateInt(COL_WIDTHS);
end;

constructor TReportSheet.Create(const AWorksheet: TsWorksheet; const AGrid: TsWorksheetGrid);
var
  GridFont: TFont;
begin
  GridFont:= TFont.Create;
  try
    GridFont.Name:= FontLikeToName(flArial);
    GridFont.Size:= 10;
    inherited Create(AWorksheet, AGrid, GridFont);
  finally
    FreeAndNil(GridFont);
  end;
end;

procedure TReportSheet.Draw(const AMonthName, APlaceName: String;
                   const ALocoNames, ALocoNums, ADepoNames, ATONames, AAptNames, AManNames: TStrVector;
                   const ASectionCounts: TIntVector);
var
  i, R: Integer;
begin
  Writer.BeginEdit;

  CaptionDraw(AMonthName, APlaceName);

  Writer.SetFont(Font.Name, Font.Size, [{fsBold}], clBlack);
  Writer.SetAlignment(haCenter, vaCenter);

  for i:= 0 to High(ALocoNames) do
  begin
    R:= 7+i;
    Writer.WriteNumber(R, 1, i+1, cbtOuter);
    Writer.WriteText(R, 2, AAptNames[i], cbtOuter);
    Writer.WriteText(R, 3, ALocoNames[i], cbtOuter);
    Writer.WriteText(R, 4, ALocoNums[i], cbtOuter);
    Writer.WriteText(R, 5, ADepoNames[i], cbtOuter);
    Writer.WriteText(R, 6, ATONames[i], cbtOuter);
    Writer.WriteNumber(R, 7, ASectionCounts[i], cbtOuter);
    Writer.WriteText(R, 8, AManNames[i], cbtOuter);
    Writer.SetRowHeight(R, ROWS_HEIGHT);
  end;

  Writer.EndEdit;
end;

end.


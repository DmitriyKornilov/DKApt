unit UAppUtils;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, DateUtils,
  //DK packages utils
  DK_Vector, DK_Matrix, DK_StrUtils;

  //AShift=0 - дневная смена, 1 - ночная смена
  function CalcBeginDT(const ADate: TDate; const AShift: Byte): TDateTime;
  function CalcEndDT(const ADate: TDate; const AShift: Byte): TDateTime;

  function ShiftDateToStr(const AShiftDate: TDateTime): String;

  function Statistic(const ALogSectionCounts: TIntVector;
                     const ALogTONames, ALogManNames, ALogSubManNames: TStrVector): TStrVector;

implementation

function CalcBeginDT(const ADate: TDate; const AShift: Byte): TDateTime;
begin
  if AShift=0 then //дневная
    Result:= EncodeTime(8,0,0,0)
  else //ночная
    Result:= EncodeTime(20,0,0,0);
  Result:= Result + ADate;
end;

function CalcEndDT(const ADate: TDate; const AShift: Byte): TDateTime;
begin
  if AShift=0 then //дневная
    Result:= EncodeTime(20,0,0,0) + ADate
  else //ночная
    Result:= EncodeTime(8,0,0,0) + IncDay(ADate);
end;

function ShiftDateToStr(const AShiftDate: TDateTime): String;
var
  D: TDate;
  H: Word;
begin
  H:= HourOf(AShiftDate);
  if H=9 then //дневная
    Result:= FormatDateTime('dd.mm.yyyy', AShiftDate);
  if H=21 then //ночная
  begin
    D:= IncDay(AShiftDate);
    if YearOf(AShiftDate)<>YearOf(D) then
      Result:= FormatDateTime('dd.mm.yyyy', AShiftDate) + '/' + FormatDateTime('dd.mm.yyyy', D)
    else begin
      if MonthOf(AShiftDate)<>MonthOf(D) then
        Result:= FormatDateTime('dd.mm', AShiftDate) + '/' + FormatDateTime('dd.mm.yyyy', D)
      else
        Result:= FormatDateTime('dd', AShiftDate) + '/' + FormatDateTime('dd.mm.yyyy', D)
    end;
  end;
end;

function Statistic(const ALogSectionCounts: TIntVector;
                   const ALogTONames, ALogManNames, ALogSubManNames: TStrVector): TStrVector;
var
  k: Integer;
  UniqueTONames{, UniqueManNames}: TStrVector;

  ManNames: TStrVector;
  SectionCounts: TIntVector;
  SubManNames: TStrMatrix;
  SubSectionCounts: TIntMatrix;

  procedure CalcData(const ATOName: String);
  var
    S1, S2: String;
    i, N, Ind1, Ind2: Integer;
  begin
    ManNames:= nil;
    SubManNames:= nil;
    SectionCounts:= nil;
    SubSectionCounts:= nil;

    for i:=0 to High(ALogTONames) do
    begin
      if not SSame(ALogTONames[i], ATOName) then continue;

      S1:= ALogManNames[i];
      S2:= ALogSubManNames[i];
      N:= ALogSectionCounts[i];

      Ind1:= VIndexOf(ManNames, S1);
      if Ind1=-1 then
      begin
        VAppend(ManNames, S1);
        VAppend(SectionCounts, N);
        Ind1:= High(ManNames);
        SetLength(SubManNames, Ind1+1);
        SetLength(SubSectionCounts, Ind1+1);
        if not SSame(S2, '<нет>') then
        begin
          VAppend(SubManNames[Ind1], S2);
          VAppend(SubSectionCounts[Ind1], N);
        end;
      end
      else begin
        SectionCounts[Ind1]:= SectionCounts[Ind1] + N;
        if not SSame(S2, '<нет>') then
        begin
          Ind2:= VIndexOf(SubManNames[Ind1], S2);
          if Ind2=-1 then
          begin
            VAppend(SubManNames[Ind1], S2);
            VAppend(SubSectionCounts[Ind1], N);
          end else
          begin
            SubSectionCounts[Ind1, Ind2]:= SubSectionCounts[Ind1, Ind2] + N;
          end;
        end;
      end;
    end;
  end;

  procedure WriteData;
  var
    i, j: Integer;
    S: String;
  begin
    for i:= 0 to High(ManNames) do
    begin
      S:= ' - ' + ManNames[i] + ' = ' + IntToStr(SectionCounts[i]);
      if not VIsNil(SubManNames[i]) then
      begin
        S:= S + ' (из них: ';
        for j:=0 to High(SubManNames[i]) do
        begin
          S:= S + SubManNames[i, j] + ' = ' + IntToStr(SubSectionCounts[i, j]);
          if j<>High(SubManNames[i]) then
            S:= S + ', ';
        end;
        S:= S + ')';
      end;
      VAppend(Result, S);
    end;
  end;

begin
  Result:= nil;
  if VIsNil(ALogTONames) then Exit;

  VAppend(Result, ' ОСМОТРЕНО СЕКЦИЙ');

  UniqueTONames:= VUnique(ALogTONames, False);
  //UniqueManNames:= VUnique(ALogManNames, False);
  for k:= 0 to High(UniqueTONames) do
  begin
    CalcData(UniqueTONames[k]);
    if Length(ManNames)>0 then
    begin
      VAppend(Result, EmptyStr);
      VAppend(Result, ' ' + UniqueTONames[k] + ':');
      WriteData;
    end;
  end;
end;

end.


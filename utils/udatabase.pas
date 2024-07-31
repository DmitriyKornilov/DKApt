unit UDataBase;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, StdCtrls,
  //DK packages utils
  DK_SQLite3, DK_SQLUtils, DK_Vector, DK_StrUtils,
  //Project utils
  UAppUtils;

type

  { TDataBase }

  TDataBase = class (TSQLite3)
  private

  public
    function SettingLoad(const ASettingName: String): String;
    procedure SettingUpdate(const ASettingName, ASettingValue: String);

    procedure SectionCountListLoad(out ASectionCounts: TIntVector);
    procedure LocoTypeListLoad(const AComboBox: TComboBox; out AIDs: TIntVector;
                               const ANeedCustomZeroID: Boolean = True);
    procedure DepoListLoad(const AComboBox: TComboBox; out AIDs: TIntVector;
                               const ANeedCustomZeroID: Boolean = True);
    procedure AptListLoad(const AComboBox: TComboBox; out AIDs: TIntVector;
                               const ANeedCustomZeroID: Boolean = True);
    procedure ManListLoad(const AComboBox: TComboBox; out AIDs: TIntVector);
    procedure SubManListLoad(const AComboBox: TComboBox; out AIDs: TIntVector);
    procedure TOTypeListLoad(const AComboBox: TComboBox; out AIDs: TIntVector);

    procedure LocoListLoad(out ALocoTypes, ALocoNums, ADepoNames, AAptNames: TStrVector;
                           out ALocoIDs, ASectionCounts, AIsCurrents, ASec1s, ASec2s, ASec3s: TIntVector;
                           const ALocoNum: String = '';
                           const ATypeID: Integer = 0;
                           const ADepoID: Integer = 0;
                           const AAptID: Integer = 0;
                           const ALocoConfig: Integer = -1);

    function LocoAdd(var ALocoID: Integer; const ALocoNum: String;
                     const ATypeID, ADepoID, AAptID, ASec1, ASec2, ASec3: Integer;
                     const ANeedCommit: Boolean = True): Boolean;
    function LocoUpdate(const ALocoID: Integer; const ALocoNum: String;
                     const ATypeID, ADepoID, AAptID, ASec1, ASec2, ASec3: Integer): Boolean;
    function LocoReconfig(var ALocoID: Integer; const ALocoNum: String;
                     const ATypeID, ADepoID, AAptID, ASec1, ASec2, ASec3: Integer): Boolean;
    function LocoLoad(const ALocoID: Integer; out ALocoNum: String;
                     out ATypeID, ADepoID, AAptID, ASec1, ASec2, ASec3: Integer): Boolean;
    function LocoDelete(const ALocoID: Integer): Boolean;

    procedure LogListLoad(const ABeginDT, AEndDT: TDateTime;
                     out ALogIDs: TInt64Vector;
                     out AManIDs, ASectionCounts: TIntVector;
                     out ADayDates, ALocoNames, ALocoNums, ADepoNames,
                         ATONames, AAptNames, AManNames, ASubManNames: TSTrVector);

    function LogAdd(const ADayDate: TDateTime;
                    const ALocoID, ATOTypeID, AManID, ASubManID: Integer): Boolean;
    function LogDelete(const ALogID: Int64): Boolean;
  end;

var
  DataBase: TDataBase;

implementation

{ TDataBase }

procedure TDataBase.SectionCountListLoad(out ASectionCounts: TIntVector);
var
  V: TStrVector;
begin
  KeyPickList('LOCOTYPES', 'LocoCount', 'LocoType', ASectionCounts, V, True, 'LocoType');
end;

procedure TDataBase.LocoTypeListLoad(const AComboBox: TComboBox; out AIDs: TIntVector;
                               const ANeedCustomZeroID: Boolean = True);
var
  S: String;
begin
  S:= EmptyStr;
  if ANeedCustomZeroID then
    S:= 'ВСЕ СЕРИИ';
  KeyPickLoad(AComboBox, AIDs, 'LOCOTYPES', 'TypeID', 'LocoType', 'LocoType',
              True{not load zero ID}, S {custom zero ID});
end;

procedure TDataBase.DepoListLoad(const AComboBox: TComboBox; out AIDs: TIntVector;
                               const ANeedCustomZeroID: Boolean = True);
var
  S: String;
begin
  S:= EmptyStr;
  if ANeedCustomZeroID then
    S:= 'ВСЕ ДЕПО';
  KeyPickLoad(AComboBox, AIDs, 'DEPO', 'DepoID', 'DepoName', 'DepoName',
              True{not load zero ID}, S {custom zero ID});
end;

procedure TDataBase.AptListLoad(const AComboBox: TComboBox; out AIDs: TIntVector;
                               const ANeedCustomZeroID: Boolean = True);
var
  S: String;
begin
  S:= EmptyStr;
  if ANeedCustomZeroID then
    S:= 'ВСЕ СИСТЕМЫ';
  KeyPickLoad(AComboBox, AIDs, 'APT', 'AptID', 'AptName', 'AptName',
              True{not load zero ID}, S {custom zero ID});
end;

procedure TDataBase.ManListLoad(const AComboBox: TComboBox; out AIDs: TIntVector);
var
  Names: TStrVector;
begin
  //KeyPickLoad(AComboBox, AIDs, 'WORKERS', 'ManID', 'ManName', 'ManID',
  //            True{not load zero ID});
  AComboBox.Items.Clear;
  AIDs:= nil;
  Names:= nil;

  QSetQuery(FQuery);
  QSetSQL(
    sqlSELECT('WORKERS', ['ManID', 'ManName']) +
    'WHERE (ShiftNum>0) ' +
    'ORDER BY ShiftNum'
  );
  QOpen;
  if not QIsEmpty then
  begin
    QFirst;
    while not QEOF do
    begin
      VAppend(AIDs, QFieldInt('ManID'));
      VAppend(Names, QFieldStr('ManName'));
      QNext;
    end;
  end;
  QClose;

  if VIsNil(AIDs) then Exit;
  VToStrings(Names, AComboBox.Items);
  AComboBox.ItemIndex:= 0;
end;

procedure TDataBase.SubManListLoad(const AComboBox: TComboBox; out AIDs: TIntVector);
begin
  KeyPickLoad(AComboBox, AIDs, 'SUBWORKERS', 'SubManID', 'SubManName', 'SubManName',
              False{load zero ID}, '<нет>');
end;

procedure TDataBase.TOTypeListLoad(const AComboBox: TComboBox; out AIDs: TIntVector);
begin
  KeyPickLoad(AComboBox, AIDs, 'TOTYPES', 'TOTypeID', 'TOTypeName', 'TOTypeName',
              True{not load zero ID});
end;

procedure TDataBase.LocoListLoad(out ALocoTypes, ALocoNums, ADepoNames, AAptNames: TStrVector;
                           out ALocoIDs, ASectionCounts, AIsCurrents, ASec1s, ASec2s, ASec3s: TIntVector;
                           const ALocoNum: String = '';
                           const ATypeID: Integer = 0;
                           const ADepoID: Integer = 0;
                           const AAptID: Integer = 0;
                           const ALocoConfig: Integer = -1);
var
  SQLStr: String;
begin
  ALocoTypes:= nil;
  ALocoNums:= nil;
  ADepoNames:= nil;
  AAptNames:= nil;
  ALocoIDs:= nil;
  ASectionCounts:= nil;
  AIsCurrents:= nil;
  ASec1s:= nil;
  ASec2s:= nil;
  ASec3s:= nil;

  SQLStr:=
    'SELECT t1.LocoID, t1.LocoNum, t1.IsCurrent, t1.Sec1, t1.Sec2, t1.Sec3, ' +
           't2.LocoType, t2.LocoCount, ' + //t2.LocoName, ' +
           't3.DepoName, ' +
           't4.AptName ' +

    'FROM LOCO t1 ' +
    'INNER JOIN LOCOTYPES t2 ON (t1.TypeID=t2.TypeID) ' +
    'INNER JOIN DEPO t3 ON (t1.DepoID=t3.DepoID) ' +
    'INNER JOIN APT t4 ON (t1.AptID=t4.AptID) ' +
    'WHERE (t1.LocoID>0) ';
  if not SEmpty(ALocoNum) then
    SQLStr:= SQLStr + 'AND (t1.LocoNum LIKE :LocoNumValue) ';
  if ATypeID>0 then
    SQLStr:= SQLStr + 'AND (t1.TypeID = :TypeIDValue) ';
  if ADepoID>0 then
    SQLStr:= SQLStr + 'AND (t1.DepoID = :DepoIDValue) ';
  if AAptID>0 then
    SQLStr:= SQLStr + 'AND (t1.AptID = :AptIDValue) ';
  if ALocoConfig>-1 then
    SQLStr:= SQLStr + 'AND (t1.IsCurrent = :LocoConfigValue) ';

  SQLStr:= SQLStr + 'ORDER BY t1.LocoNum, t2.LocoType, t1.IsCurrent DESC';

  QSetQuery(FQuery);
  QSetSQL(SQLStr);
  QParamInt('TypeIDValue', ATypeID);
  QParamInt('DepoIDValue', ADepoID);
  QParamInt('AptIDValue', AAptID);
  QParamInt('LocoConfigValue', ALocoConfig);
  QParamStr('LocoNumValue', {'%'+}ALocoNum+'%');
  QOpen;
  if not QIsEmpty then
  begin
    QFirst;
    while not QEOF do
    begin
      VAppend(ALocoIDs, QFieldInt('LocoID'));

      VAppend(ALocoTypes, QFieldStr('LocoType'));
      VAppend(ALocoNums, QFieldStr('LocoNum'));
      VAppend(ADepoNames, QFieldStr('DepoName'));
      VAppend(AAptNames, QFieldStr('AptName'));

      VAppend(ASectionCounts, QFieldInt('LocoCount'));
      VAppend(AIsCurrents, QFieldInt('IsCurrent'));
      VAppend(ASec1s, QFieldInt('Sec1'));
      VAppend(ASec2s, QFieldInt('Sec2'));
      VAppend(ASec3s, QFieldInt('Sec3'));

      QNext;
    end;
  end;
  QClose;
end;

function TDataBase.LocoAdd(var ALocoID: Integer; const ALocoNum: String;
        const ATypeID, ADepoID, AAptID, ASec1, ASec2, ASec3: Integer;
        const ANeedCommit: Boolean = True): Boolean;
begin
  Result:= False;
  QSetQuery(FQuery);
  try
    //запись основных данных
    QSetSQL(
      sqlINSERT('LOCO', ['TypeID', 'LocoNum', 'DepoID', 'AptID', 'Sec1', 'Sec2', 'Sec3'])
    );
    QParamStr('LocoNum', ALocoNum);
    QParamInt('TypeID', ATypeID);
    QParamInt('DepoID', ADepoID);
    QParamInt('AptID', AAptID);
    QParamInt('Sec1', ASec1);
    QParamInt('Sec2', ASec2);
    QParamInt('Sec3', ASec3);
    QExec;
    //получение ID сделанной записи
    ALocoID:= LastWritedInt32ID('LOCO');
    if ANeedCommit then QCommit;
    Result:= True;
  except
    if ANeedCommit then QRollback;
  end;
end;

function TDataBase.LocoUpdate(const ALocoID: Integer; const ALocoNum: String;
  const ATypeID, ADepoID, AAptID, ASec1, ASec2, ASec3: Integer): Boolean;
begin
  Result:= False;
  QSetQuery(FQuery);
  try
    QSetSQL(
      sqlUPDATE('LOCO', ['TypeID', 'LocoNum', 'DepoID', 'AptID', 'Sec1', 'Sec2', 'Sec3']) +
      'WHERE LocoID=:LocoID'
    );
    QParamInt('LocoID', ALocoID);
    QParamStr('LocoNum', ALocoNum);
    QParamInt('TypeID', ATypeID);
    QParamInt('DepoID', ADepoID);
    QParamInt('AptID', AAptID);
    QParamInt('Sec1', ASec1);
    QParamInt('Sec2', ASec2);
    QParamInt('Sec3', ASec3);
    QExec;
    QCommit;
    Result:= True;
  except
    QRollback;
  end;
end;

function TDataBase.LocoReconfig(var ALocoID: Integer; const ALocoNum: String;
  const ATypeID, ADepoID, AAptID, ASec1, ASec2, ASec3: Integer): Boolean;
begin
  try
    Result:= UpdateInt32ID('LOCO', 'IsCurrent', 'LocoID', ALocoID, 0, False{no commit});
    if not Result then Exit;
    LocoAdd(ALocoID, ALocoNum, ATypeID, ADepoID, AAptID, ASec1, ASec2, ASec3, False{no commit});
    QCommit;
    Result:= True;
  except
    QRollback;
  end;
end;

function TDataBase.LocoLoad(const ALocoID: Integer; out ALocoNum: String; out
  ATypeID, ADepoID, AAptID, ASec1, ASec2, ASec3: Integer): Boolean;
begin
  Result:= False;

  QSetQuery(FQuery);
  QSetSQL(
    'SELECT * FROM LOCO ' +
    'WHERE LocoID = :LocoID'

  );
  QParamInt('LocoID', ALocoID);
  QOpen;
  if not QIsEmpty then
  begin
    QFirst;
    ALocoNum:= QFieldStr('LocoNum');
    ATypeID:= QFieldInt('TypeID');
    ADepoID:= QFieldInt('DepoID');
    AAptID:= QFieldInt('AptID');
    ASec1:= QFieldInt('Sec1');
    ASec2:= QFieldInt('Sec2');
    ASec3:= QFieldInt('Sec3');
    Result:= True;
  end;
  QClose;
end;

function TDataBase.LocoDelete(const ALocoID: Integer): Boolean;
begin
  Result:= Delete('LOCO', 'LocoID', ALocoID);
end;

procedure TDataBase.LogListLoad(const ABeginDT, AEndDT: TDateTime;
                     out ALogIDs: TInt64Vector;
                     out AManIDs, ASectionCounts: TIntVector;
                     out ADayDates, ALocoNames, ALocoNums, ADepoNames,
                         ATONames, AAptNames, AManNames, ASubManNames: TSTrVector);

  var
  SQLStr: String;
begin
  ALogIDs:= nil;
  AManIDs:= nil;
  ASectionCounts:= nil;
  ADayDates:= nil;
  ALocoNames:= nil;
  ALocoNums:= nil;
  ADepoNames:= nil;
  ATONames:= nil;
  AAptNames:= nil;
  AManNames:= nil;
  ASubManNames:= nil;

  SQLStr:=
    'SELECT t1.LogID, t1.DayDate, t1.ToTypeID, t1.ManID, ' +
           't2.ManName, t3.SubManName, ' +
           't4.LocoNum, t4.Sec1, t4.Sec2, t4.Sec3, '  +
           't5.LocoName, ' + //t5.LocoCount, ' +
           't6.AptName, t7.TOTypeName, t8.DepoName '+
    'FROM LOGS t1 ' +
    'INNER JOIN WORKERS t2 ON (t1.ManID=t2.ManID) ' +
    'INNER JOIN SUBWORKERS t3 ON (t1.SubManID=t3.SubManID) ' +
    'INNER JOIN LOCO t4 ON (t1.LocoID=t4.LocoID) ' +
    'INNER JOIN LOCOTYPES t5 ON (t4.TypeID=t5.TypeID) ' +
    'INNER JOIN APT t6 ON (t4.AptID=t6.AptID) ' +
    'INNER JOIN TOTYPES t7 ON (t1.TOTypeID=t7.TOTypeID) ' +
    'INNER JOIN DEPO t8 ON (t4.DepoID=t8.DepoID) ' +
    'WHERE (t1.DayDate BETWEEN :BD AND :ED) ';
  SQLStr:= SQLStr + 'ORDER BY t1.DayDate';

  QSetQuery(FQuery);
  QSetSQL(SQLStr);
  QParamDT('BD', ABeginDT);
  QParamDT('ED', AEndDT);
  QOpen;
  if not QIsEmpty then
  begin
    QFirst;
    while not QEOF do
    begin
      VAppend(ALogIDs, QFieldInt64('LogID'));
      //VAppend(ASectionCounts, QFieldInt('LocoCount'));
      VAppend(ASectionCounts, QFieldInt('Sec1')+QFieldInt('Sec2')+QFieldInt('Sec3'));
      VAppend(AManIDs, QFieldInt('ManID'));

      VAppend(ADayDates, ShiftDateToStr(QFieldDT('DayDate')));
      VAppend(ALocoNames, QFieldStr('LocoName'));
      VAppend(ALocoNums, QFieldStr('LocoNum'));
      VAppend(ADepoNames, QFieldStr('DepoName'));
      VAppend(AAptNames, QFieldStr('AptName'));
      VAppend(ATONames, QFieldStr('TOTypeName'));
      VAppend(AManNames, QFieldStr('ManName'));
      VAppend(ASubManNames, QFieldStr('SubManName'));

      QNext;
    end;
  end;
  QClose;
end;

function TDataBase.LogAdd(const ADayDate: TDateTime;
                      const ALocoID, ATOTypeID, AManID, ASubManID: Integer): Boolean;
begin
  Result:= False;
  QSetQuery(FQuery);
  try
    QSetSQL(
      sqlINSERT('LOGS', ['DayDate', 'LocoID', 'TOTypeID', 'ManID', 'SubManID'])
    );
    QParamDT('DayDate', ADayDate);
    QParamInt('LocoID', ALocoID);
    QParamInt('TOTypeID', ATOTypeID);
    QParamInt('ManID', AManID);
    QParamInt('SubManID', ASubManID);
    QExec;

    QCommit;
    Result:= True;
  except
    QRollback;
  end;
end;

function TDataBase.LogDelete(const ALogID: Int64): Boolean;
begin
  Result:= Delete('LOGS', 'LogID', ALogID);
end;

function TDataBase.SettingLoad(const ASettingName: String): String;
begin
  Result:= ValueStrStrID('SETTINGS', 'SettingValue', 'SettingName', ASettingName);
end;

procedure TDataBase.SettingUpdate(const ASettingName, ASettingValue: String);
begin
  UpdateStrID('SETTINGS', 'SettingValue', 'SettingName', ASettingName, ASettingValue, True {commit});
end;



end.


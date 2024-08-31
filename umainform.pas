unit UMainForm;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, BCButton,
  Buttons, Menus, DividerBevel,
  //DK packages utils
  {DK_HeapTrace,} DK_LCLStrRus, DK_Fonts, DK_CtrlUtils, DK_VSTTypes,
  //Project utils
  UDataBase, UUiUtils,
  //Forms
  ULogForm, UReportForm, ULocoListForm, UAboutForm;

type

  { TMainForm }

  TMainForm = class(TForm)
    AboutButton: TSpeedButton;
    LogButton: TBCButton;
    DictionaryButton: TBCButton;
    DictionaryMenu: TPopupMenu;
    DividerBevel1: TDividerBevel;
    DividerBevel2: TDividerBevel;
    MainPanel: TPanel;
    ExitButton: TSpeedButton;
    AptListMenuItem: TMenuItem;
    DepoListMenuItem: TMenuItem;
    ReportButton: TBCButton;
    TOTypeListMenuItem: TMenuItem;
    RefreshButton: TSpeedButton;
    Separator1: TMenuItem;
    Separator2: TMenuItem;
    LocoListMenuItem: TMenuItem;
    WorkerListMenuItem: TMenuItem;
    SubWorkerListMenuItem: TMenuItem;
    LokoTypeListMenuItem: TMenuItem;
    ToolPanel: TPanel;
    procedure AboutButtonClick(Sender: TObject);
    procedure AptListMenuItemClick(Sender: TObject);
    procedure DepoListMenuItemClick(Sender: TObject);
    procedure DictionaryButtonClick(Sender: TObject);
    procedure ExitButtonClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure LocoListMenuItemClick(Sender: TObject);
    procedure LogButtonClick(Sender: TObject);
    procedure LokoTypeListMenuItemClick(Sender: TObject);
    procedure RefreshButtonClick(Sender: TObject);
    procedure ReportButtonClick(Sender: TObject);
    procedure SubWorkerListMenuItemClick(Sender: TObject);
    procedure TOTypeListMenuItemClick(Sender: TObject);
    procedure WorkerListMenuItemClick(Sender: TObject);
  private
    Category: Byte;
    CategoryForm: TForm;
    procedure DBConnect;
    procedure DictionarySelect(const ADictionary: Byte);
    procedure ViewUpdate;
  public
    procedure CategorySelect(const ACategory: Byte);
  end;

var
  MainForm: TMainForm;

implementation

{$R *.lfm}

{TODO: обновление данных при редактировании справочников!!!}


{ TMainForm }

procedure TMainForm.FormCreate(Sender: TObject);
begin
  //HeapTraceOutputFile('trace.trc');
  Caption:= 'DKApt v.2.0.0 - Учет технического обслуживания систем АПТ';
  DBConnect;
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  FreeAndNil(DataBase);
end;

procedure TMainForm.FormShow(Sender: TObject);
begin
  SetToolPanels([
    ToolPanel
  ]);
  SetToolButtons([
    RefreshButton, AboutButton, ExitButton
  ]);
  SetCategoryButtons([
    DictionaryButton, ReportButton, LogButton
  ]);

  DictionaryMenu.Images:= ImageListForScreen;

  CategorySelect(1);
end;

procedure TMainForm.DBConnect;
var
  DBPath, DBName, DDLName: String;
begin
  DBPath:= ExtractFilePath(Application.ExeName) + DirectorySeparator + 'db' + DirectorySeparator;
  DBName:= DBPath + 'base.db';
  DDLName:= DBPath + 'ddl.sql';

  DataBase:= TDataBase.Create;
  DataBase.Connect(DBName);
  DataBase.ExecuteScript(DDLName);
end;

procedure TMainForm.ExitButtonClick(Sender: TObject);
begin
  Close;
end;

procedure TMainForm.LogButtonClick(Sender: TObject);
begin
  CategorySelect(1);
end;

procedure TMainForm.ReportButtonClick(Sender: TObject);
begin
  CategorySelect(2);
end;

procedure TMainForm.DictionaryButtonClick(Sender: TObject);
begin
  ControlPopupMenuShow(Sender, DictionaryMenu);
end;

procedure TMainForm.AptListMenuItemClick(Sender: TObject);
begin
  DictionarySelect(1);
end;

procedure TMainForm.TOTypeListMenuItemClick(Sender: TObject);
begin
  DictionarySelect(2);
end;

procedure TMainForm.LokoTypeListMenuItemClick(Sender: TObject);
begin
  DictionarySelect(3);
end;

procedure TMainForm.DepoListMenuItemClick(Sender: TObject);
begin
  DictionarySelect(4);
end;

procedure TMainForm.LocoListMenuItemClick(Sender: TObject);
begin
  DictionarySelect(5);
end;

procedure TMainForm.WorkerListMenuItemClick(Sender: TObject);
begin
  DictionarySelect(6);
end;

procedure TMainForm.SubWorkerListMenuItemClick(Sender: TObject);
begin
  DictionarySelect(7);
end;

procedure TMainForm.DictionarySelect(const ADictionary: Byte);
var
  IsOK: Boolean;
begin
  IsOK:= False;
  case ADictionary of
    1: IsOK:= DataBase.EditList('Системы АПТ',
                'APT', 'AptID', 'AptName', True, True{, 400, GridFont});
    2: IsOK:= DataBase.EditList('Виды ТО (ТР)',
                'TOTYPES', 'TOTypeID', 'TOTypeName', True, True{, 400, GridFont});
    3: IsOK:= DataBase.EditTable('Серии локомотивов',
                          'LOCOTYPES', 'TypeID',
                          ['LocoType',     'LocoName',   'LocoCount'        ],
                          ['Серия',        'В отчетах',  'Количество секций'],
                          [ ctString,       ctString,    ctInteger          ],
                          [ True,           True,        True               ],
                          [ 150,            150,         150                ],
                          [ taLeftJustify,  taCenter,    taCenter           ],
                          True, ['LocoType'], 1{, nil, nil, GridFont});
    4: IsOK:= DataBase.EditList('Депо приписки',
                'DEPO', 'DepoID', 'DepoName', True, True{, 400, GridFont});
    5:
      begin
        IsOK:= True;
        FormModalShow(TLocoListForm);
      end;
    6: IsOK:= DataBase.EditTable('Основные исполнители',
                          'WORKERS', 'ManID',
                          ['ManName',      'ShiftNum'     ],
                          ['Ф.И.О.',       '№ смены'      ],
                          [ ctString,       ctInteger     ],
                          [ True,           True          ],
                          [ 200,            100           ],
                          [ taLeftJustify,  taCenter      ],
                          True, ['ShiftNum'], 1{, nil, nil, GridFont});
    7: IsOK:= DataBase.EditList('Замещающие исполнители',
                'SUBWORKERS', 'SubManID', 'SubManName', True, True{, 400, GridFont});

  end;

  if IsOK then ViewUpdate;
end;

procedure TMainForm.ViewUpdate;
begin
  if not Assigned(CategoryForm) then Exit;

  case Category of
    1: (CategoryForm as TLogForm).ViewUpdate;
    2: (CategoryForm as TReportForm).ViewUpdate;
  end;
end;

procedure TMainForm.CategorySelect(const ACategory: Byte);
begin
  if ACategory=Category then Exit;

  Screen.Cursor:= crHourGlass;
  try
    Category:= ACategory;

    if Assigned(CategoryForm) then FreeAndNil(CategoryForm);
    case Category of
      1: CategoryForm:= FormOnPanelCreate(TLogForm, MainPanel);
      2: CategoryForm:= FormOnPanelCreate(TReportForm, MainPanel);
    end;

    LogButton.Down:= False;
    ReportButton.Down:= False;
    if Assigned(CategoryForm) then
    begin
      case Category of
        1: LogButton.Down:= True;
        2: ReportButton.Down:= True;
      end;

      CategoryForm.Show;
      ViewUpdate;
    end;

  finally
    Screen.Cursor:= crDefault;
  end;
end;

procedure TMainForm.RefreshButtonClick(Sender: TObject);
begin
  DataBase.Reconnect;
  ViewUpdate;
end;

procedure TMainForm.AboutButtonClick(Sender: TObject);
begin
  FormModalShow(TAboutForm);
end;

end.


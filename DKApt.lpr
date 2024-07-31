program DKApt;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  {$IFDEF HASAMIGA}
  athreads,
  {$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms, UMainForm, UImages, lazcontrols, datetimectrls, UDataBase,
  UUiUtils, ULocoListForm, UTables, ULocoEditForm, UAppUtils, UReportForm, 
ULogForm, UAboutForm, USheets
  { you can add units after this };

{$R *.res}

begin
  RequireDerivedFormResource:=True;
  Application.Scaled:=True;
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.CreateForm(TImages, Images);
  Application.Run;
end.


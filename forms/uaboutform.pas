unit UAboutForm;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ExtCtrls,
  StdCtrls, Buttons, LCLIntf;

type

  { TAboutForm }

  TAboutForm = class(TForm)
    Image1: TImage;
    Label1: TLabel;
    Memo1: TMemo;

    procedure FormShow(Sender: TObject);

  private

  public

  end;

var
  AboutForm: TAboutForm;

implementation

uses DK_Fonts;

{$R *.lfm}

{ TAboutForm }

procedure TAboutForm.FormShow(Sender: TObject);
begin
  Memo1.Font.Name:= FontLikeToName(flArial);
  Memo1.Font.Size:= 10;
  Label1.Font.Name:= FontLikeToName(flArial);
  Label1.Font.Size:= 12;
end;

end.


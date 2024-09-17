unit UImages;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Controls, Forms, Buttons;

type

  { TImages }

  TImages = class(TDataModule)
    PX24: TImageList;
    PX42: TImageList;
    PX36: TImageList;
    PX30: TImageList;
  private

  public
    function ForCurrentPPI: TImageList;
    procedure ToButtons(const AButtons: array of TSpeedButton);
  end;

var
  Images: TImages;

implementation

{$R *.lfm}

{ TImages }

function TImages.ForCurrentPPI: TImageList;
var
  PPI: Integer;
begin
  PPI:= Screen.PixelsPerInch;
  if PPI<108 then
    Result:= PX24
  else if PPI<132 then
    Result:= PX30
  else if PPI<156 then
    Result:= PX36
  else
    Result:= PX42;
end;

procedure TImages.ToButtons(const AButtons: array of TSpeedButton);
var
  i: Integer;
  L: TImageList;
begin
  L:= ForCurrentPPI;
  for i:= 0 to High(AButtons) do
    AButtons[i].Images:= L;
end;

end.


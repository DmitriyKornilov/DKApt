unit UUiUtils;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Graphics, Controls, BCPanel, BCButton, Buttons, Forms,
  //DK packages utils
  DK_CtrlUtils, DK_StrUtils,
  //Project utils
  UImages;

  procedure SetToolPanels(const AControls: array of TControl);
  procedure SetCaptionPanels(const AControls: array of TBCPanel);
  procedure SetToolButtons(const AControls: array of TSpeedButton);
  procedure SetCategoryButtons(const AControls: array of TBCButton);
  procedure SetEditButtons(const AControls: array of TSpeedButton);
  function ImageListForScreen: TImageList;

implementation

procedure SetToolPanels(const AControls: array of TControl);
var
  i: Integer;
begin
  for i:= 0 to High(AControls) do
    ControlHeight(AControls[i], TOOL_PANEL_HEIGHT_DEFAULT);
end;

procedure SetCaptionPanels(const AControls: array of TBCPanel);
var
  i, h: Integer;
  c: TColor;
begin
  h:= Round(TOOL_PANEL_HEIGHT_DEFAULT*0.65);
  c:= cl3DLight;
  //c:= ColorIncLightness(clBtnFace, -15);
  for i:= 0 to High(AControls) do
  begin
    ControlHeight(AControls[i], h);
    AControls[i].Background.Color:= c;
    AControls[i].Border.Color:= clActiveBorder;
    AControls[i].Rounding.RoundX:= 0;
    AControls[i].Rounding.RoundY:= 0;
  end;
end;

procedure SetToolButtons(const AControls: array of TSpeedButton);
var
  i: Integer;
  ImageList: TImageList;
begin
  ImageList:= ImageListForScreen;
  for i:= 0 to High(AControls) do
  begin
    ControlWidth(AControls[i], TOOL_BUTTON_WIDTH_DEFAULT);
    AControls[i].Images:= ImageList;
  end;
end;

procedure SetCategoryButtons(const AControls: array of TBCButton);
var
  i: Integer;
  c: TColor;
  ImageList: TImageList;
begin
  c:= cl3DLight;
  //c:= ColorIncLightness(clBtnFace, -15);
  ImageList:= ImageListForScreen;
  for i:= 0 to High(AControls) do
  begin
    AControls[i].Images:= ImageList;
    AControls[i].StateNormal.Background.Color:= c;
    AControls[i].StateNormal.Border.Color:= clActiveBorder;
  end;
end;

procedure SetEditButtons(const AControls: array of TSpeedButton);
var
  i, W, H: Integer;
  C: TControl;
begin
  C:= AControls[0].Parent;
  H:= C.Scale96ToForm(EDIT_BUTTON_HEIGHT_DEFAULT);
  W:= AControls[0].Width;
  for i:= 1 to High(AControls) do
    if SLength(AControls[i].Caption)>SLength(AControls[i-1].Caption) then
      W:= AControls[i].Width;
  W:= W + C.Scale96ToForm(EDIT_BUTTON_WIDTH_EXTRA);
  for i:= 0 to High(AControls) do
  begin
    AControls[i].Constraints.MinHeight:= H;
    AControls[i].Constraints.MinWidth:= W;
  end;
end;

function ImageListForScreen: TImageList;
begin
  case Screen.PixelsPerInch of
    96 : Result:= Images.PX24;
    120: Result:= Images.PX30;
    144: Result:= Images.PX36;
    168: Result:= Images.PX42;
  end;
end;

end.


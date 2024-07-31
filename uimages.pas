unit UImages;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Controls;

type

  { TImages }

  TImages = class(TDataModule)
    PX24: TImageList;
    PX42: TImageList;
    PX36: TImageList;
    PX30: TImageList;
  private

  public

  end;

var
  Images: TImages;

implementation

{$R *.lfm}

end.


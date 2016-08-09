unit UEditItem;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls, UConst;

type

  { TForm2 }

  TForm2 = class(TForm)
    BtnSave: TButton;
    ComboBoxCategory: TComboBox;
    ComboBoxLocation: TComboBox;
    Edit1: TEdit;
    Edit2: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    LblName: TLabel;
    procedure BtnSaveClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormKeyPress(Sender: TObject; var Key: char);
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  Form2: TForm2;

implementation

{$R *.lfm}

{ TForm2 }

procedure TForm2.FormCreate(Sender: TObject);
var
  Item: String;
begin
  ComboBoxCategory.Items.Clear;
  for Item in Categorys do
  begin
    ComboBoxCategory.Items.Append(Item);
  end;
  ComboBoxCategory.ItemIndex:=0;
  KeyPreview := True;
end;

procedure TForm2.FormKeyPress(Sender: TObject; var Key: char);
begin
  if Key = #126 then
  begin
    ComboBoxLocation.SetFocus;
    Key := #0;
  end;
end;

procedure TForm2.BtnSaveClick(Sender: TObject);
begin
  ModalResult:=111;
end;

end.


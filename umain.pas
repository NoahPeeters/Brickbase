unit UMain;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, Grids, Menus,
  StdCtrls, ExtCtrls, simpleipc, DateUtils, lclintf, UEditItem, UConst;

type
  TPart = record
    ID: LongWord;
    Produced1: Word;
    Produced2: Word;
    Color: Word;
    Color_Family: Byte;
    Stock: Integer;
    Used: Integer;
  end;

  TPartArray = Array of TPart;

  TDesign = record
    ID: LongWord;
    Name: String;
    Category: Byte;
    Parts: TPartArray;
    Location: String;
  end;

  TDesignArray = Array of TDesign;
  TStringArray = Array of String;

  { TForm1 }

  TForm1 = class(TForm)
    BtnAdd: TButton;
    BtnUse: TButton;
    BtnSearch: TButton;
    BtnViewOnline: TButton;
    CheckBoxInStock: TCheckBox;
    ComboBoxLocation: TComboBox;
    ComboBoxYear1: TComboBox;
    ComboBoxYear2: TComboBox;
    ComboBoxCategory: TComboBox;
    ComboBoxColor: TComboBox;
    EdtName: TEdit;
    EdtID: TEdit;
    ImgItem: TImage;
    LblFixLocation: TLabel;
    LblName: TLabel;
    LblID: TLabel;
    LblColor: TLabel;
    LblColorID: TLabel;
    LblFixCategory: TLabel;
    LblFixDash: TLabel;
    LblFixColor: TLabel;
    LblFixId: TLabel;
    LblFixName: TLabel;
    MainMenu: TMainMenu;
    MenuImport: TMenuItem;
    MenuFile: TMenuItem;
    MenuViewOnline: TMenuItem;
    MenuSearch: TMenuItem;
    MenuSearchID: TMenuItem;
    MenuEdit: TMenuItem;
    MenuSearchCategory: TMenuItem;
    MenuSearchName: TMenuItem;
    MenuOpen: TMenuItem;
    MenuSave: TMenuItem;
    MenuSaveAs: TMenuItem;
    DialogImport: TOpenDialog;
    DialogOpen: TOpenDialog;
    DialogSave: TSaveDialog;
    PopupMenu1: TPopupMenu;
    StrGrdItem: TStringGrid;
    StrGrdColor: TStringGrid;
    Timer1: TTimer;
    procedure BtnAddClick(Sender: TObject);
    procedure BtnUseClick(Sender: TObject);
    procedure BtnSearchClick(Sender: TObject);
    procedure BtnViewOnlineClick(Sender: TObject);
    procedure CheckBoxInStockChange(Sender: TObject);
    procedure ComboBoxColorChange(Sender: TObject);
    procedure ComboBoxLocationKeyPress(Sender: TObject; var Key: char);
    procedure ComboBoxYear1Change(Sender: TObject);
    procedure ComboBoxYear2Change(Sender: TObject);
    procedure ComboBoxCategoryChange(Sender: TObject);
    procedure EdtNameKeyPress(Sender: TObject; var Key: char);
    procedure EdtIDKeyPress(Sender: TObject; var Key: char);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormKeyPress(Sender: TObject; var Key: char);
    procedure LoadImage(id: LongWord);
    procedure MenuImportClick(Sender: TObject);
    procedure MenuViewOnlineClick(Sender: TObject);
    procedure MenuSearchIDClick(Sender: TObject);
    procedure MenuEditClick(Sender: TObject);
    procedure MenuSearchCategoryClick(Sender: TObject);
    procedure MenuSearchNameClick(Sender: TObject);
    procedure MenuOpenClick(Sender: TObject);
    procedure MenuSaveAsClick(Sender: TObject);
    procedure MenuSaveClick(Sender: TObject);
    procedure PopupMenu1Popup(Sender: TObject);
    procedure StrGrdItemMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure StrGrdItemSelectCell(Sender: TObject; aCol, aRow: Integer;
      var CanSelect: Boolean);
    procedure StrGrdColorSelectCell(Sender: TObject; aCol, aRow: Integer;
      var CanSelect: Boolean);
    procedure Timer1Timer(Sender: TObject);
    procedure UpdateList();
    procedure UpdateDetails(ID: LongWord);
    procedure UpdateColorDetails(ID: LongWord);
    procedure DisableDetails();
    procedure Changed();
    procedure LoadBase();
    procedure SaveBase();
    procedure UpdateLocations(ComboBox: TComboBox);
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  Form1: TForm1;
  Saved: boolean = False;
  Changes: boolean = False;
  Path: String;
  Designs: TDesignArray;
  CurrentDesign, CurrentID: LongWord;
  InUpdate: Boolean;

implementation

{$R *.lfm}

{ TForm1 }

/////////////////////
//                 //
//   Prepare/Lib   //
//                 //
/////////////////////

procedure TForm1.FormCreate(Sender: TObject);
var
  I: Integer;
  Item: String;
begin
  KeyPreview := True;

  //Prepare Year Combo Boxes
  ComboBoxYear1.Items.Clear;
  ComboBoxYear2.Items.Clear;
  for I:=YearOf(Date) DownTo FirstYear do
  begin
    ComboBoxYear1.Items.Append(IntToStr(I));
    ComboBoxYear2.Items.Append(IntToStr(I));
  end;
  ComboBoxYear1.ItemIndex:=YearOf(Date)-I;
  ComboBoxYear2.ItemIndex:=0;

  //Prepare Category Combo Box
  ComboBoxCategory.Items.Clear;
  ComboBoxCategory.Items.Append('All');
  for Item in Categorys do
  begin
    ComboBoxCategory.Items.Append(Item);
  end;
  ComboBoxCategory.ItemIndex:=0;

  //Prepare Color Combo Box
  ComboBoxColor.Items.Clear;
  ComboBoxColor.Items.Append('All');
  for Item in ColorFalmilies do
  begin
    ComboBoxColor.Items.Append(Item);
  end;
  ComboBoxColor.ItemIndex:=0;
  UpdateList;

  //Enable Sorting
  StrGrdItem.ColumnClickSorts:=True;
  StrGrdColor.ColumnClickSorts:=True;

  //Load Database
  Timer1.Enabled:=True;
end;

procedure TForm1.FormKeyPress(Sender: TObject; var Key: char);
begin
  if Key = #126 then
  begin
    ComboBoxLocation.SetFocus;
    Key := #0;
  end;
end;

procedure TForm1.Timer1Timer(Sender: TObject);
begin
  Timer1.Enabled:=False;
  LoadBase();
end;

procedure TForm1.LoadImage(id: LongWord);
begin
  try
    if FileExists(ExtractFileDir(ExtractFileDir(Application.ExeName))+'/Resources/Images/'+IntToStr(id)+'.jpg') then
      ImgItem.Picture.LoadFromFile(ExtractFileDir(ExtractFileDir(Application.ExeName))+'/Resources/Images/'+IntToStr(id)+'.jpg')
    else
      ImgItem.Picture.LoadFromFile(ExtractFileDir(ExtractFileDir(Application.ExeName))+'/Resources/Images/0.jpg');
  except
    ShowMessage('Cannot load image!');
  end;
end;

procedure TForm1.Changed();
begin
  Changes:=True;
  if Saved then
    Form1.Caption:= 'Lego Database - ' + ExtractFileName(Path) + '*'
  else
    Form1.Caption:= 'Lego Database - Untitled*';
end;

/////////////////////
//                 //
//  Color Buttons  //
//                 //
/////////////////////

procedure TForm1.BtnAddClick(Sender: TObject);
var
  answer: String;
  value, i: Integer;
begin
  try
    answer:=InputBox('Add Parts', 'How many do you want to add?', '0');
    value := StrToInt(answer);
    if Designs[CurrentDesign].Parts[CurrentID].Stock + value >=0 then
    begin
      Designs[CurrentDesign].Parts[CurrentID].Stock := Designs[CurrentDesign].Parts[CurrentID].Stock + value;
      value := 0;
      for i:=0 to length(Designs[CurrentDesign].Parts)-1 do
        value := value + Designs[CurrentDesign].Parts[i].Stock;
      StrGrdItem.Cells[3, StrGrdItem.Selection.Top]:=IntToStr(value);
      StrGrdColor.Cells[3, StrGrdColor.Selection.Top]:=IntToStr(Designs[CurrentDesign].Parts[CurrentID].Stock);
      Changed;
    end
    else
    begin
      ShowMessage('You don''t have so many!');
    end;
  except
    ShowMessage('"' + answer + '" is not a number!')
  end;
end;

procedure TForm1.BtnUseClick(Sender: TObject);
var
  answer: String;
  value: Integer;
begin
  try
    answer:=InputBox('Use Parts', 'How many do you want to use?', '0');
    value := StrToInt(answer);
    if (Designs[CurrentDesign].Parts[CurrentID].Stock - value >=0) and (Designs[CurrentDesign].Parts[CurrentID].Used + value >= 0) then
    begin
      Designs[CurrentDesign].Parts[CurrentID].Stock := Designs[CurrentDesign].Parts[CurrentID].Stock - value;
      Designs[CurrentDesign].Parts[CurrentID].Used := Designs[CurrentDesign].Parts[CurrentID].Used + value;
      StrGrdColor.Cells[3, StrGrdColor.Selection.Top]:=IntToStr(Designs[CurrentDesign].Parts[CurrentID].Stock);
      StrGrdColor.Cells[4, StrGrdColor.Selection.Top]:=IntToStr(Designs[CurrentDesign].Parts[CurrentID].Used);
      Changed;
    end
    else
    begin
      ShowMessage('You don''t have so many!');
    end;
  except
    ShowMessage('"' + answer + '" is not a number!')
  end;
end;

procedure TForm1.BtnViewOnlineClick(Sender: TObject);
begin
  OpenURL('http://brickset.com/parts/' + StrGrdColor.Cells[1, StrGrdColor.Selection.Top]);
end;

////////////////////
//                //
//     Search     //
//                //
////////////////////
procedure TForm1.BtnSearchClick(Sender: TObject);
begin
  UpdateList;
end;

procedure TForm1.CheckBoxInStockChange(Sender: TObject);
begin
  UpdateList;
end;

procedure TForm1.ComboBoxColorChange(Sender: TObject);
begin
  UpdateList;
end;

procedure TForm1.ComboBoxYear1Change(Sender: TObject);
begin
  UpdateList;
end;

procedure TForm1.ComboBoxYear2Change(Sender: TObject);
begin
  UpdateList;
end;

procedure TForm1.ComboBoxCategoryChange(Sender: TObject);
begin
  UpdateList;
end;

procedure TForm1.EdtNameKeyPress(Sender: TObject; var Key: char);
begin
  if (Key = #13) or (Key = #3) then
  begin
    Key := #0;
    UpdateList;
  end;
end;

procedure TForm1.ComboBoxLocationKeyPress(Sender: TObject; var Key: char);
begin
  if (Key = #13) or (Key = #3) then
  begin
    Key := #0;
    UpdateList;
  end;
end;

procedure TForm1.EdtIDKeyPress(Sender: TObject; var Key: char);
begin
  if (Key = #13) or (Key = #3) then
  begin
    Key := #0;
    UpdateList;
  end;
end;

procedure TForm1.MenuSearchIDClick(Sender: TObject);
begin
  EdtID.Text:=StrGrdItem.Cells[0, StrGrdItem.Selection.Top];
  UpdateList;
end;

procedure TForm1.MenuSearchCategoryClick(Sender: TObject);
var
  I: Integer;
begin
  for I := 0 to High(Categorys) do
  begin
    if StrGrdItem.Cells[2, StrGrdItem.Selection.Top] = Categorys[I] then
    begin
      ComboBoxCategory.ItemIndex:=I+1;
      break;
    end;
  end;
end;

procedure TForm1.MenuSearchNameClick(Sender: TObject);
begin
  EdtName.Text:=StrGrdItem.Cells[1, StrGrdItem.Selection.Top];
  UpdateList;
end;

////////////////////
//                //
// Saving Wrapper //
//                //
////////////////////

procedure TForm1.FormClose(Sender: TObject; var CloseAction: TCloseAction);
var
  buttonSelected : Integer;
begin
  if Changes then
  begin
     buttonSelected := MessageDlg('Do you want to save the changes?',mtConfirmation,
                              mbYesNoCancel, 0);
     if      buttonSelected = mrYes    then MenuSaveClick(Nil)
     else if buttonSelected = mrCancel then Application.Run();
  end;
end;

///////////////////
//               //
//  Update View  //
//               //
///////////////////

procedure TForm1.UpdateColorDetails(ID: LongWord);
var
  I: Integer;
begin
  for I := 0 to High(Designs[CurrentDesign].Parts) do
  begin
    if ID = Designs[CurrentDesign].Parts[I].ID then
    begin
      CurrentID:=I;
      break;
    end;
  end;
  LblColor.Caption:=Colors[Designs[CurrentDesign].Parts[CurrentID].Color];
  LblColorID.Caption:=IntToStr(Designs[CurrentDesign].Parts[CurrentID].ID);
  LoadImage(Designs[CurrentDesign].Parts[CurrentID].ID);

  BtnAdd.Enabled:=True;
  BtnUse.Enabled:=True;
  BtnViewOnline.Enabled:=True;
end;

procedure TForm1.UpdateDetails(ID: LongWord);
var
  I, Current_Size: Integer;
begin
  for I := 0 to High(Designs) do
  begin
    if ID = Designs[I].ID then
    begin
      CurrentDesign:=I;
      break;
    end;
  end;
  LblName.Caption:=Designs[CurrentDesign].Name;
  LblID.Caption:=IntToStr(Designs[CurrentDesign].ID);
  Current_Size:=0;
  StrGrdColor.RowCount:=1;
  for I:= 0 to High(Designs[CurrentDesign].Parts) do
  begin
    if ((EdtID.Text = '') or (AnsiPos(EdtID.Text, IntToStr(Designs[CurrentDesign].Parts[I].ID)) <> 0) or (AnsiPos(EdtID.Text, IntToStr(Designs[CurrentDesign].ID)) <> 0)) and ((Designs[CurrentDesign].Parts[I].Stock + Designs[CurrentDesign].Parts[I].Used > 0) or (not CheckBoxInStock.Checked)) and ((ComboBoxColor.ItemIndex = 0) or (ComboBoxColor.ItemIndex-1 = Designs[CurrentDesign].Parts[I].Color_Family)) and ((StrToInt(ComboBoxYear1.Items.Strings[ComboBoxYear1.ItemIndex]) <= Designs[CurrentDesign].Parts[I].Produced2) and (StrToInt(ComboBoxYear2.Items.Strings[ComboBoxYear2.ItemIndex]) >= Designs[CurrentDesign].Parts[I].Produced1)) and ((ComboBoxLocation.Text = '') or ((Designs[CurrentDesign].Parts[I].Stock > 0) or (Designs[CurrentDesign].Parts[I].Used > 0))) then
    begin
      Inc(Current_Size);
      StrGrdColor.RowCount:=Current_Size+1;
      StrGrdColor.Cells[0, Current_Size]:= Colors[Designs[CurrentDesign].Parts[I].Color];
      StrGrdColor.Cells[1, Current_Size]:= IntToStr(Designs[CurrentDesign].Parts[I].ID);
      StrGrdColor.Cells[2, Current_Size]:= IntToStr(Designs[CurrentDesign].Parts[I].Produced1) + ' - ' + IntToStr(Designs[CurrentDesign].Parts[I].Produced2);
      StrGrdColor.Cells[3, Current_Size]:= IntToStr(Designs[CurrentDesign].Parts[I].Stock);
      StrGrdColor.Cells[4, Current_Size]:= IntToStr(Designs[CurrentDesign].Parts[I].Used);
    end;
  end;
  StrGrdColor.Enabled:=True;
  if StrGrdColor.Cells[1, StrGrdColor.Selection.Top] <> '' then
     UpdateColorDetails(StrToInt(StrGrdColor.Cells[1, StrGrdColor.Selection.Top]));
end;

procedure TForm1.DisableDetails();
begin
  LblName.Caption:='Nothing selected';
  LblID.Caption:='No ID';
  LblColor.Caption:='Nothing selected';
  LblColorID.Caption:='No ID';
  StrGrdColor.RowCount:=1;
  StrGrdColor.Enabled:=False;
  BtnAdd.Enabled:=False;
  BtnUse.Enabled:=False;
  BtnViewOnline.Enabled:=False;
  LoadImage(0);
end;

procedure TForm1.UpdateList();
var
  I, J, Current_Size, Stock: Integer;
  ColorExists, YearOK, TextOK, IDOK: Boolean;
  Temp1: TStrings;
  CurrentRow: TStrings;
begin
  Current_Size:=0;
  StrGrdItem.RowCount:=1;
  DisableDetails;
  Temp1 := TStringList.Create;
  Temp1.Text := StringReplace(EdtName.Text, #32, #13#10, [rfReplaceAll]);
  CurrentRow := TStringList.Create;
  CurrentRow.AddStrings(['', '', '', '']);
  StrGrdItem.BeginUpdate;
  InUpdate:=True;

  for I:= 0 to High(Designs) do
  begin
    Stock:=0;
    ColorExists:= False;
    YearOK:=False;
    TextOK:=True;
    IDOK:=False;
    for J:=0 to Temp1.Count-1 do
    begin
      if (AnsiPos(LowerCase(Temp1[J]), LowerCase(Designs[I].Name)) = 0) then
      begin
        TextOK:=False;
        break;
      end;
    end;

    if (EdtID.Text = '') or (AnsiPos(EdtID.Text, IntToStr(Designs[I].ID)) <> 0) then
      IDOK:=True;

    for J:=0 to High(Designs[I].Parts) do
    begin
      Stock := Stock + Designs[I].Parts[J].Stock + Designs[I].Parts[J].Used;
      if ((ComboBoxColor.ItemIndex = 0) or (ComboBoxColor.ItemIndex-1 = Designs[I].Parts[J].Color_Family)) then
        ColorExists:=True;
      if ((StrToInt(ComboBoxYear1.Items.Strings[ComboBoxYear1.ItemIndex]) <= Designs[I].Parts[J].Produced2) and (StrToInt(ComboBoxYear2.Items.Strings[ComboBoxYear2.ItemIndex]) >= Designs[I].Parts[J].Produced1))  then
        YearOK:=True;
      if (EdtID.Text = '') or (AnsiPos(EdtID.Text, IntToStr(Designs[I].Parts[J].ID)) <> 0) then
         IDOK:=True;
    end;
    if IDOK and TextOK and YearOK and ColorExists and ((ComboBoxCategory.ItemIndex = 0) or (ComboBoxCategory.ItemIndex-1 = Designs[I].Category)) and ((Stock > 0) or (not CheckBoxInStock.Checked)) and ((ComboBoxLocation.Text = '') or (ComboBoxLocation.Text = Designs[I].Location)) then
    begin
      Inc(Current_Size);
      StrGrdItem.RowCount:=Current_Size+1;
      CurrentRow[0]:= IntToStr(Designs[I].ID);
      CurrentRow[1]:= Designs[I].Name;
      CurrentRow[2]:= Categorys[Designs[I].Category];
      CurrentRow[3]:= IntToStr(Stock);
      StrGrdItem.Rows[Current_Size] := CurrentRow;
    end;
  end;
  if StrGrdItem.Cells[0, StrGrdItem.Selection.Top] <> '' then
    UpdateDetails(StrToInt(StrGrdItem.Cells[0, StrGrdItem.Selection.Top]));
  StrGrdItem.EndUpdate;
  InUpdate:=False;
end;

procedure TForm1.UpdateLocations(ComboBox: TComboBox);
var
  I: Integer;
begin
  ComboBox.Items.Clear;
  ComboBox.Items.Append('');
  for I := 0 to High(Designs) do
  begin
    if ComboBox.Items.IndexOf(Designs[I].Location) = -1 then
    begin
      ComboBox.Items.Append(Designs[I].Location);
    end;
  end;
end;

//////////////////////
//                  //
// Save/Open/Import //
//                  //
//////////////////////
procedure TForm1.LoadBase();
var
  Stream: TFileStream;
  I, J, Len: Integer;
  P: String;
begin
  P:=ExtractFileDir(ExtractFileDir(Application.ExeName))+'/Resources/database.legobasedb';
  try
    Stream := TFileStream.Create(P, fmOpenRead);
    Stream.Read(Len, SizeOf(Len));
    SetLength(Designs, Len);
    for I := 0 to Len - 1 do
    begin
      Stream.Read(Designs[I].ID, SizeOf(Designs[I].ID));
      Stream.Read(Len, SizeOf(Len));
      SetLength(Designs[I].Name, Len);
      Stream.Read(PChar(Designs[I].Name)^, Len);
      Stream.Read(Designs[I].Category, SizeOf(Designs[I].Category));
      Stream.Read(Len, SizeOf(Len));
      SetLength(Designs[I].Parts, Len);
      for J:=0 to High(Designs[I].Parts) do
      begin
        Stream.Read(Designs[I].Parts[J].ID, SizeOf(Designs[I].Parts[J].ID));
        Stream.Read(Designs[I].Parts[J].Produced1, SizeOf(Designs[I].Parts[J].Produced1));
        Stream.Read(Designs[I].Parts[J].Produced2, SizeOf(Designs[I].Parts[J].Produced2));
        Stream.Read(Designs[I].Parts[J].Color, SizeOf(Designs[I].Parts[J].Color));
        Stream.Read(Designs[I].Parts[J].Color_Family, SizeOf(Designs[I].Parts[J].Color_Family));
        Designs[I].Parts[J].Stock:=0;
        Designs[I].Parts[J].Used:=0;
        Designs[I].Location:='';
      end;
    end;
    Changes:=False;
    UpdateList;
    UpdateLocations(ComboBoxLocation);
  except
    ShowMessage('Could not load base database!');
  end;
  Stream.Free;
end;

procedure TForm1.SaveBase();
var
  Stream: TFileStream;
  I, J, Len: Integer;
  P: String;
begin
  P:=ExtractFileDir(ExtractFileDir(Application.ExeName))+'/Resources/database.legobasedb';
  try
    Stream := TFileStream.Create(P, fmCreate);
    Len:= Length(Designs);
    Stream.Write(Len, SizeOf(Len));
    for I:=0 To Len -1 do
    begin
      Stream.Write(Designs[I].ID, SizeOf(Designs[I].ID));
      Len:=Length(Designs[I].Name);
      Stream.Write(Len, SizeOf(Len));
      Stream.Write(PChar(Designs[I].Name)^, Len);
      Stream.Write(Designs[I].Category, SizeOf(Designs[I].Category));
      Len:= Length(Designs[I].Parts);
      Stream.Write(Len, SizeOf(Len));
      for J:=0 to High(Designs[I].Parts) do
      begin
        Stream.Write(Designs[I].Parts[J].ID, SizeOf(Designs[I].Parts[J].ID));
        Stream.Write(Designs[I].Parts[J].Produced1, SizeOf(Designs[I].Parts[J].Produced1));
        Stream.Write(Designs[I].Parts[J].Produced2, SizeOf(Designs[I].Parts[J].Produced2));
        Stream.Write(Designs[I].Parts[J].Color, SizeOf(Designs[I].Parts[J].Color));
        Stream.Write(Designs[I].Parts[J].Color_Family, SizeOf(Designs[I].Parts[J].Color_Family));
      end;
    end;

    Changes:=False;
    Saved:=True;
    Form1.Caption:= 'Lego Database - ' + ExtractFileName(Path);
  except
    ShowMessage('Could not save base database!');
  end;
  Stream.Free;
end;

procedure TForm1.MenuOpenClick(Sender: TObject);
var
  Stream: TFileStream;
  I, J, I1, J1, Len, FullLen: Integer;
  ID_Design, ID_Color: LongWord;
begin
  if DialogOpen.Execute then
  begin
    Path:=DialogOpen.FileName;
    try
      Stream := TFileStream.Create(Path, fmOpenRead);
      Stream.Read(FullLen, SizeOf(FullLen));
      for I := 0 to FullLen - 1 do
      begin
        Stream.Read(ID_Design, SizeOf(ID_Design));
        for I1 := 0 to High(Designs) do
        begin
          if ID_Design = Designs[I1].ID then
          begin
            break;
          end;
        end;

        Stream.Read(Len, SizeOf(Len));
        SetLength(Designs[I1].Location, Len);
        Stream.Read(PChar(Designs[I1].Location)^, Len);
        Stream.Read(Len, SizeOf(Len));
        for J:=0 to Len-1 do
        begin
          Stream.Read(ID_Color, SizeOf(ID_Color));
          for J1 := 0 to High(Designs[I1].Parts) do
          begin
            if ID_Color = Designs[I1].Parts[J1].ID then
            begin
              break;
            end;
          end;
          Stream.Read(Designs[I1].Parts[J1].Stock, SizeOf(Designs[I1].Parts[J1].Stock));
          Stream.Read(Designs[I1].Parts[J1].Used, SizeOf(Designs[I1].Parts[J1].Used));
        end;
      end;
      Changes:=False;
      Saved:=True;
      Form1.Caption:= 'Lego Database - ' + ExtractFileName(Path);
      UpdateList;
      UpdateLocations(ComboBoxLocation);
    except
      ShowMessage('Could not load database!');
    end;
    Stream.Free;
  end;
end;

procedure TForm1.MenuSaveAsClick(Sender: TObject);
begin
  if DialogSave.Execute then
  begin
    Path:=DialogSave.FileName;
    Saved:=True;
    MenuSaveClick(Sender);
  end;
end;

procedure TForm1.MenuSaveClick(Sender: TObject);
var
  Stream: TFileStream;
  I, J, Len: Integer;
begin
  if not Saved then
  begin
    MenuSaveAsClick(Sender)
  end
  else
  begin
    try
      Stream := TFileStream.Create(Path, fmCreate);
      Len:= Length(Designs);
      Stream.Write(Len, SizeOf(Len));
      for I:=0 To Len -1 do
      begin
        Stream.Write(Designs[I].ID, SizeOf(Designs[I].ID));
        Len:=Length(Designs[I].Location);
        Stream.Write(Len, SizeOf(Len));
        Stream.Write(PChar(Designs[I].Location)^, Len);
        Len:= Length(Designs[I].Parts);
        Stream.Write(Len, SizeOf(Len));
        for J:=0 to High(Designs[I].Parts) do
        begin
          Stream.Write(Designs[I].Parts[J].ID, SizeOf(Designs[I].Parts[J].ID));
          Stream.Write(Designs[I].Parts[J].Stock, SizeOf(Designs[I].Parts[J].Stock));
          Stream.Write(Designs[I].Parts[J].Used, SizeOf(Designs[I].Parts[J].Used));
        end;
      end;

      Changes:=False;
      Saved:=True;
      Form1.Caption:= 'Lego Database - ' + ExtractFileName(Path);
    except
      ShowMessage('Could not save database!');
    end;
    Stream.Free;
  end;
  SaveBase();
end;

procedure TForm1.MenuImportClick(Sender: TObject);
var
  Stream: TFileStream;
  I, J, Len: Integer;
begin
  if DialogImport.Execute then
  begin
    Path:=DialogImport.FileName;
    try
      Stream := TFileStream.Create(Path, fmOpenRead);
      Stream.Read(Len, SizeOf(Len));
      SetLength(Designs, Len);
      for I := 0 to Len - 1 do
      begin
        Stream.Read(Designs[I].ID, SizeOf(Designs[I].ID));
        Stream.Read(Len, SizeOf(Len));
        SetLength(Designs[I].Name, Len);
        Stream.Read(PChar(Designs[I].Name)^, Len);
        Stream.Read(Designs[I].Category, SizeOf(Designs[I].Category));
        Stream.Read(Len, SizeOf(Len));
        SetLength(Designs[I].Parts, Len);
        for J:=0 to High(Designs[I].Parts) do
        begin
          Stream.Read(Designs[I].Parts[J].ID, SizeOf(Designs[I].Parts[J].ID));
          Stream.Read(Designs[I].Parts[J].Produced1, SizeOf(Designs[I].Parts[J].Produced1));
          Stream.Read(Designs[I].Parts[J].Produced2, SizeOf(Designs[I].Parts[J].Produced2));
          Stream.Read(Designs[I].Parts[J].Color, SizeOf(Designs[I].Parts[J].Color));
          Stream.Read(Designs[I].Parts[J].Color_Family, SizeOf(Designs[I].Parts[J].Color_Family));
          Stream.Read(Designs[I].Parts[J].Stock, SizeOf(Designs[I].Parts[J].Stock));
          Stream.Read(Designs[I].Parts[J].Used, SizeOf(Designs[I].Parts[J].Used));
        end;
      end;
      Changes:=False;
      Saved:=True;
      Form1.Caption:= 'Lego Database - ' + ExtractFileName(Path);
      UpdateList;
      UpdateLocations(ComboBoxLocation);
    except
      ShowMessage('Could not load database!');
    end;
    Stream.Free;
  end;
end;

//////////////////////
//                  //
//      Popup       //
//                  //
//////////////////////
procedure TForm1.MenuEditClick(Sender: TObject);
var
  I: Integer;
  found: boolean;
begin
  Form2.Edit1.Text:=StrGrdItem.Cells[0, StrGrdItem.Selection.Top];
  Form2.Edit2.Text:=StrGrdItem.Cells[1, StrGrdItem.Selection.Top];
  Form2.ComboBoxCategory.ItemIndex:=Designs[CurrentDesign].Category;
  Form2.ComboBoxLocation.Text:=Designs[CurrentDesign].Location;
  UpdateLocations(Form2.ComboBoxLocation);
  if Form2.ShowModal() = 111 then
  begin
    try
      found := False;
      if Form2.Edit1.Text <> StrGrdItem.Cells[0, StrGrdItem.Selection.Top] then
      begin
        for I := 0 to High(Designs) do
        begin
          if Designs[I].ID = StrToInt(Form2.Edit1.Text) then
          begin
            found:=True;
            break;
          end;
        end;
      end;
      if not found then
      begin
        Designs[CurrentDesign].ID:=StrToInt(Form2.Edit1.Text);
        Designs[CurrentDesign].Name:=Form2.Edit2.Text;
        Designs[CurrentDesign].Category:=Form2.ComboBoxCategory.ItemIndex;
        Designs[CurrentDesign].Location:=Form2.ComboBoxLocation.Text;
        StrGrdItem.Cells[0, StrGrdItem.Selection.Top]:=Form2.Edit1.Text;
        StrGrdItem.Cells[1, StrGrdItem.Selection.Top]:=Form2.Edit2.Text;
        StrGrdItem.Cells[2, StrGrdItem.Selection.Top]:=Categorys[Form2.ComboBoxCategory.ItemIndex];
        UpdateDetails(Designs[CurrentDesign].ID);
        UpdateLocations(ComboBoxLocation);
        Changed;
      end
      else
      begin
        ShowMessage('This ID is already in use!');
      end;
    except
      ShowMessage('Please enter a valid ID!');
    end;
  end;
end;

procedure TForm1.PopupMenu1Popup(Sender: TObject);
var
  clickable: boolean;
begin
  clickable := StrGrdItem.Selection.Top <> 0;
  MenuViewOnline.Enabled:=clickable;
  MenuSearch.Enabled:=clickable;
  MenuEdit.Enabled:=clickable;
end;

procedure TForm1.MenuViewOnlineClick(Sender: TObject);
begin
  OpenURL('http://brickset.com/parts/design-' + StrGrdItem.Cells[0, StrGrdItem.Selection.Top]);
end;

//////////////////////
//                  //
//      StrGrd      //
//                  //
//////////////////////
procedure TForm1.StrGrdItemMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  ACol, ARow:Integer;
begin
  StrGrdItem.MouseToCell(x,y,ACol,ARow);

  if Button = mbRight then
  begin
      StrGrdItem.Row := ARow;
  end;
end;

procedure TForm1.StrGrdItemSelectCell(Sender: TObject; aCol, aRow: Integer;
  var CanSelect: Boolean);
begin
  if not InUpdate and (StrGrdItem.Cells[0, aRow] <> '') then
     UpdateDetails(StrToInt(StrGrdItem.Cells[0, aRow]));
end;

procedure TForm1.StrGrdColorSelectCell(Sender: TObject; aCol, aRow: Integer;
  var CanSelect: Boolean);
begin
  if StrGrdColor.Cells[1, aRow] <> '' then
     UpdateColorDetails(StrToInt(StrGrdColor.Cells[1, aRow]));
end;


end.

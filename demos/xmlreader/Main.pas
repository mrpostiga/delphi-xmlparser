(**
===============================================================================================
Name    : Main
===============================================================================================
Project : XML Reader
===============================================================================================
Subject : Main Window
===============================================================================================
Date        Author Changes
-----------------------------------------------------------------------------------------------
2000-03-26  HeySt  Start
2000-04-24  HeySt  Commented out reference to 'Contnrs' unit
2000-06-30  HeySt  Toolbar introduced
                   Apply changes to Tree/DTD Tree/Content if Source changes
2001-07-03  HeySt  Show more info for DTD
*)

unit Main;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  Menus, ComCtrls, ExtCtrls, StdCtrls, ImgList, ShellApi,
  LibXmlParser, ToolWin;

type
  TFrmMain = class(TForm)
    MnuMain: TMainMenu;
    MnuFile: TMenuItem;
    MnuOpen: TMenuItem;
    N1: TMenuItem;
    MnuExit: TMenuItem;
    PageControl: TPageControl;
    TshContents: TTabSheet;
    TshSource: TTabSheet;
    TshTree: TTabSheet;
    TshDtd: TTabSheet;
    MmoContents: TRichEdit;
    MmoSource: TRichEdit;
    TrvDoc: TTreeView;
    SplitterTree: TSplitter;
    TrvDtd: TTreeView;
    SplitterDtd: TSplitter;
    DlgOpen: TOpenDialog;
    IglTree: TImageList;
    Panel1: TPanel;
    LvwAttr: TListView;
    Splitter1: TSplitter;
    MmoContent: TMemo;
    ToolBar: TToolBar;
    ToolButton1: TToolButton;
    Bevel1: TBevel;
    TshAbout: TTabSheet;
    PnlAbout: TPanel;
    Label1: TLabel;
    LblDestructorLink: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Panel2: TPanel;
    ImgDestructor: TImage;
    MmoDtd: TMemo;
    procedure MnuExitClick(Sender: TObject);
    procedure MnuOpenClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormHide(Sender: TObject);
    procedure TrvDocChanging(Sender: TObject; Node: TTreeNode;
      var AllowChange: Boolean);
    procedure MmoSourceChange(Sender: TObject);
    procedure PageControlChange(Sender: TObject);
    procedure TrvDtdChange(Sender: TObject; Node: TTreeNode);
    procedure LblDestructorLinkClick(Sender: TObject);
  private
    XmlParser   : TXmlParser;
  public
    Elements   : TObjectList;
    CreateTree : BOOLEAN;
    Changed    : BOOLEAN;  // TRUE, if Source has changed
    PROCEDURE FillContent;
    PROCEDURE FillTree;
    PROCEDURE FillDtdTree;
    PROCEDURE ReadFile (Filename : STRING);
    PROCEDURE ApplySource;
  end;

var
  FrmMain: TFrmMain;

const
  Img_Tag          = 0;
  Img_TagWithAttr  = 1;
  Img_UndefinedTag = 2;
  Img_AttrDef      = 3;
  Img_EntityDef    = 4;
  Img_ParEntityDef = 5;
  Img_Text         = 6;
  Img_Comment      = 7;
  Img_PI           = 8;
  Img_DTD          = 9;
  Img_Notation     = 10;
  Img_Prolog       = 11;

  CRLF             = ^M^J;

(*
===============================================================================================
IMPLEMENTATION
===============================================================================================
*)

IMPLEMENTATION

{$R *.DFM}

(*
===============================================================================================
TElementNode
===============================================================================================
*)

TYPE
  TElementNode = CLASS
                   Content : STRING;
                   Attr    : TStringList;
                   CONSTRUCTOR Create (TheContent : STRING; TheAttr : TNvpList);
                   DESTRUCTOR Destroy; OVERRIDE;
                 END;

CONSTRUCTOR TElementNode.Create (TheContent : STRING; TheAttr : TNvpList);
VAR
  I : INTEGER;
BEGIN
  INHERITED Create;
  Content := TheContent;
  Attr    := TStringList.Create;
  IF TheAttr <> NIL THEN
    FOR I := 0 TO TheAttr.Count-1 DO
      Attr.Add (TNvpNode (TheAttr [I]).Name + '=' + TNvpNode (TheAttr [I]).Value);
END;


DESTRUCTOR TElementNode.Destroy;
BEGIN
  Attr.Free;
  INHERITED Destroy;
END;


(*
===============================================================================================
TFrmMain
===============================================================================================
*)

procedure TFrmMain.FormShow(Sender: TObject);
begin
  XmlParser := TXmlParser.Create;
  Changed := FALSE;
  Elements := TObjectList.Create;
  PageControl.ActivePage := PageControl.Pages [0];
  if ParamCount > 0 then
    ReadFile (ParamStr (1));
end;

procedure TFrmMain.FormHide(Sender: TObject);
begin
  TrvDoc.Items.Clear;
  Elements.Free;
  XmlParser.Free;
end;


procedure TFrmMain.MnuExitClick(Sender: TObject);
begin
  Close;
end;


PROCEDURE TFrmMain.FillContent;
          // Directly appending to TRichEdits is very slow, but LoadFromFile is fast. So I'll use this ...
VAR
  Filename : STRING;
  f        : TEXTFILE;
BEGIN
  Filename := ExtractFilePath (Application.ExeName)+'Contents.txt';
  AssignFile (f, Filename);
  TRY
    Rewrite (f);
    TRY
      XmlParser.StartScan;
      XmlParser.Normalize := FALSE;
      WHILE XmlParser.Scan DO
        IF (XmlParser.CurPartType = ptContent) OR
           (XmlParser.CurPartType = ptCData) THEN
          Write (f, XmlParser.CurContent);
    FINALLY
      CloseFile (f);
      END;

    MmoContents.PlainText := TRUE;
    MmoContents.Lines.LoadFromFile (Filename);
  EXCEPT
    MmoContents.Lines.Clear;
    END;
  DeleteFile (Filename);
END;


PROCEDURE TFrmMain.FillTree;

  PROCEDURE ScanElement (Parent : TTreeNode);
  VAR
    Node : TTreeNode;
    Strg : STRING;
    EN   : TElementNode;
  BEGIN
    WHILE XmlParser.Scan DO BEGIN
      Node := NIL;
      CASE XmlParser.CurPartType OF
        ptXmlProlog : BEGIN
                        Node := TrvDoc.Items.AddChild (Parent, '<?xml?>');
                        Node.ImageIndex := Img_Prolog;
                        EN := TElementNode.Create (StrSFPas (XmlParser.CurStart, XmlParser.CurFinal), NIL);
                        Node.Data := EN;
                      END;
        ptDtdc      : BEGIN
                        Node := TrvDoc.Items.AddChild (Parent, 'DTD');
                        Node.ImageIndex := Img_Dtd;
                        EN := TElementNode.Create (StrSFPas (XmlParser.CurStart, XmlParser.CurFinal), NIL);
                        Node.Data := EN;
                      END;
        ptStartTag,
        ptEmptyTag  : BEGIN
                        Node := TrvDoc.Items.AddChild (Parent, XmlParser.CurName);
                        IF XmlParser.CurAttr.Count > 0 THEN BEGIN
                          Node.ImageIndex := Img_TagWithAttr;
                          EN := TElementNode.Create ('', XmlParser.CurAttr);
                          Elements.Add (EN);
                          Node.Data := EN;
                          END
                        ELSE
                          Node.ImageIndex := Img_Tag;

                        IF XmlParser.CurPartType = ptStartTag THEN   // Recursion
                          ScanElement (Node);
                      END;
        ptEndTag    : BREAK;
        ptContent,
        ptCData     : BEGIN
                        Node := TrvDoc.Items.AddChild (Parent, '---');  // !!!
                        Node.ImageIndex := Img_Text;
                        EN := TElementNode.Create (XmlParser.CurContent, NIL);
                        Node.Data := EN;
                      END;
        ptComment   : BEGIN
                        Node := TrvDoc.Items.AddChild (Parent, 'Comment');
                        Node.ImageIndex := Img_Comment;
                        SetStringSF (Strg, XmlParser.CurStart+4, XmlParser.CurFinal-3);
                        EN := TElementNode.Create (TrimWs (Strg), NIL);
                        Node.Data := EN;
                      END;
        ptPI        : BEGIN
                        Node := TrvDoc.Items.AddChild (Parent, XmlParser.CurName + ' ' + XmlParser.CurContent);
                        Node.ImageIndex := Img_PI;
                      END;
        END;
      IF Node <> NIL THEN
        Node.SelectedIndex := Node.ImageIndex;
      END;
  END;

BEGIN
  TrvDoc.Items.BeginUpdate;
  TrvDoc.Items.Clear;
  XmlParser.Normalize := TRUE;
  XmlParser.StartScan;

  ScanElement (NIL);

  TrvDoc.Items.EndUpdate;
END;


PROCEDURE TFrmMain.FillDtdTree;
VAR
  MainNode    : TTreeNode;
  Node        : TTreeNode;
  SubNode     : TTreeNode;
  I, K        : INTEGER;
  ElemDef     : TElemDef;
  AttrDef     : TAttrDef;
  NotationDef : TNotationDef;

  PROCEDURE FillEntities (MainNode : TTreeNode; ImageIndex : INTEGER; List : TNvpList);
  VAR
    EntityDef : TEntityDef;
  VAR
    I : INTEGER;
  BEGIN
    FOR I := 0 TO List.Count-1 DO BEGIN
      EntityDef := TEntityDef (List [I]);
      Node := TrvDtd.Items.AddChildObject (MainNode, EntityDef.Name, EntityDef);   // !!! TObject
      Node.ImageIndex := ImageIndex;
      Node.SelectedIndex := ImageIndex;
      END;
  END;

BEGIN
  TrvDtd.Items.BeginUpdate;
  TrvDtd.Items.Clear;
  XmlParser.Normalize := TRUE;
  XmlParser.StartScan;
  WHILE XmlParser.Scan DO                      // Scan until DTD is read in
    IF XmlParser.CurPartType = ptDtdc THEN
      BREAK;

  // --- Fill Elements
  MainNode := TrvDtd.Items.AddObject (NIL, 'Elements', NIL);
  MainNode.ImageIndex := Img_Tag;
  MainNode.SelectedIndex := Img_Tag;
  FOR I := 0 TO XmlParser.Elements.Count-1 DO BEGIN
    ElemDef := TElemDef (XmlParser.Elements [I]);
    Node := TrvDtd.Items.AddChildObject (MainNode, ElemDef.Name, ElemDef);  // !!! TObject
    Node.ImageIndex    := Img_Tag;
    Node.SelectedIndex := Img_Tag;
    FOR K := 0 TO ElemDef.Count-1 DO BEGIN
      AttrDef := TAttrDef (ElemDef [K]);
      SubNode := TrvDtd.Items.AddChildObject (Node, AttrDef.Name, AttrDef);
      SubNode.ImageIndex    := Img_AttrDef;
      SubNode.SelectedIndex := Img_AttrDef;
      END;
    END;

  // --- Fill Parameter Entities
  MainNode := TrvDtd.Items.AddObject (NIL, 'Parameter Entities', NIL);
  MainNode.ImageIndex := Img_ParEntityDef;
  MainNode.SelectedIndex := Img_ParEntityDef;
  FillEntities (MainNode, Img_ParEntityDef, XmlParser.ParEntities);

  // --- Fill General Entities
  MainNode := TrvDtd.Items.AddObject (NIL, 'General Entities', NIL);
  MainNode.ImageIndex := Img_EntityDef;
  MainNode.SelectedIndex := Img_EntityDef;
  FillEntities (MainNode, Img_EntityDef, XmlParser.Entities);

  // --- Fill Notations
  MainNode := TrvDtd.Items.AddObject (NIL, 'Notations', NIL);
  MainNode.ImageIndex := Img_Notation;
  MainNode.SelectedIndex := Img_Notation;
  FOR I := 0 TO XmlParser.Notations.Count-1 DO BEGIN
    NotationDef := TNotationDef (XmlParser.Notations [I]);
    Node := TrvDtd.Items.AddChildObject (MainNode, NotationDef.Name, NotationDef);   // !!! TObject
    Node.ImageIndex := Img_Notation;
    Node.SelectedIndex := Img_Notation;
    END;

  TrvDtd.Items.EndUpdate;
END;


PROCEDURE TFrmMain.ReadFile (Filename : STRING);
BEGIN
  Screen.Cursor := crHourGlass;
  Caption := 'XML Reader - '+Filename;
  Elements.Clear;

  // --- Load Source Memo
  MmoSource.PlainText := TRUE;
  MmoSource.Lines.LoadFromFile (Filename);

  // --- Apply Source
  ApplySource;
END;


PROCEDURE TFrmMain.ApplySource;
BEGIN
  Screen.Cursor := crHourGlass;
  // --- Load XML File
  XmlParser.LoadFromBuffer (MmoSource.Lines.GetText);

  // --- First Scan: Fill the "Content" page
  FillContent;

  // --- Second Scan: Fill Element tree
  CreateTree := TRUE;
  FillTree;

  // --- Third Scan: Fill DTD tree
  FillDtdTree;
  CreateTree := FALSE;

  Changed       := FALSE;
  Screen.Cursor := crDefault;
END;


procedure TFrmMain.MnuOpenClick(Sender: TObject);
begin
  if DlgOpen.Execute THEN
    ReadFile (DlgOpen.Filename);
end;


procedure TFrmMain.TrvDocChanging(Sender: TObject; Node: TTreeNode;
  var AllowChange: Boolean);
VAR
  EN   : TElementNode;
  I    : INTEGER;
  Item : TListItem;
begin
  IF CreateTree THEN EXIT;
  IF Node.Data = NIL THEN BEGIN
    LvwAttr.Items.Clear;
    MmoContent.Lines.Clear;
    EXIT;
    END;

  EN := TElementNode (Node.Data);
  MmoContent.Lines.Text := EN.Content;

  LvwAttr.Items.BeginUpdate;
  LvwAttr.Items.Clear;
  FOR I := 0 TO EN.Attr.Count-1 DO BEGIN
    Item := LvwAttr.Items.Add;
    Item.Caption := EN.Attr.Names [I];
    Item.SubItems.Add (EN.Attr.Values [EN.Attr.Names [I]]);
    END;
  LvwAttr.Items.EndUpdate;
end;

procedure TFrmMain.MmoSourceChange(Sender: TObject);
begin
  Changed := TRUE;
end;

procedure TFrmMain.PageControlChange(Sender: TObject);
begin
  IF PageControl.ActivePage <> TshSource THEN
    IF Changed THEN
      ApplySource;
end;

procedure TFrmMain.TrvDtdChange(Sender: TObject; Node: TTreeNode);
var
  ElemDef     : TElemDef;
  AttrDef     : TAttrDef;
  EntityDef   : TEntityDef;
  NotationDef : TNotationDef;
begin
  MmoDtd.Lines.Clear;
  IF (TrvDtd.Selected <> NIL) AND (TrvDtd.Selected.Data <> NIL) THEN BEGIN
    CASE TrvDtd.Selected.ImageIndex OF
      Img_Tag          : BEGIN
                           ElemDef := TElemDef (TrvDtd.Selected.Data);
                           MmoDtd.Lines.Text := 'Name: ' + ElemDef.Name                      + CRLF +
                                                'Type: ' + CElemType_Name [ElemDef.ElemType] + CRLF +
                                                CRLF +
                                                ElemDef.Definition;
                         END;
      Img_AttrDef      : BEGIN
                           AttrDef := TAttrDef (TrvDtd.Selected.Data);
                           MmoDtd.Lines.Text := 'Name     : ' + AttrDef.Name + CRLF +
                                                'Type     : ' + CAttrType_Name [AttrDef.AttrType] + CRLF;
                           CASE AttrDef.AttrType OF
                             atUnknown,
                             atCData,
                             atID,
                             atIdRef,
                             atIdRefs,
                             atEntity,
                             atEntities,
                             atNmToken,
                             atNmTokens    : ;
                             atNotation    : MmoDtd.Lines.Add ('Notations: ' + AttrDef.Notations);
                             atEnumeration : MmoDtd.Lines.Add ('Values   : ' + AttrDef.TypeDef);
                             END;
                           MmoDtd.Lines.Add ('');
                           CASE AttrDef.DefaultType OF
                             adDefault  : MmoDtd.Lines.Add ('Default  : ' + AnsiQuotedStr (AttrDef.Value, ''''));
                             adRequired : MmoDtd.Lines.Add ('Default  : None. Value always required.');
                             adImplied  : MmoDtd.Lines.Add ('Default  : None. Value implied.');
                             adFixed    : MmoDtd.Lines.Add ('Value    : Fixed to ' + AnsiQuotedStr (AttrDef.Value, ''''));
                             END;
                         END;
      Img_EntityDef,
      Img_ParEntityDef : BEGIN
                           EntityDef := TEntityDef (TrvDtd.Selected.Data);
                           MmoDtd.Lines.Add ('Name : ' + EntityDef.Name);
                           IF EntityDef.SystemId <> '' THEN
                             MmoDtd.Lines.Add ('Value: Loaded from ' + AnsiQuotedStr (EntityDef.SystemId, ''''));
                           IF EntityDef.PublicId <> '' THEN
                             MmoDtd.Lines.Add ('Value: Assumed from ' + AnsiQuotedStr (EntityDef.PublicId, '''') +
                                                       ' or loaded from ' + AnsiQuotedStr (EntityDef.SystemId, ''''));
                           IF EntityDef.Value <> '' THEN
                             MmoDtd.Lines.Add ('Value: ' + AnsiQuotedStr (EntityDef.Value, ''''));
                         END;
      Img_Notation     : BEGIN
                           NotationDef := TNotationDef (TrvDtd.Selected.Data);
                           MmoDtd.Lines.Add ('Name     : ' + NotationDef.Name);
                           MmoDtd.Lines.Add ('System ID: ' + NotationDef.Value);
                           MmoDtd.Lines.Add ('Public ID: ' + NotationDef.PublicId);
                         END;
      END;
    END;
end;

procedure TFrmMain.LblDestructorLinkClick(Sender: TObject);
begin
  ShellExecute (Handle, 'open', 'http://www.destructor.de', '', '', sw_ShowNormal);
end;

end.

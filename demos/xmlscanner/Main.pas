(**
===============================================================================================
Name    : Main
===============================================================================================
Project : XmlScannerDemo
===============================================================================================
Subject : Demonstration of the TXmlScanner VCL Component
===============================================================================================
This is a simple demonstration of the destructor.de TXmlScanner VCL Component.
TXmlScanner (unit LibXmlComps) is a VCL wrapper for TXmlParser (unit LibXmlParser).

NOTE:
If you read in large XML files with this demo, the TTreeView easily gets problems with
its own memory handling. So if the app crashes, blame TTreeView (i.e. the underlying
Windows common control) first.

The size of XML file which you can process with TXmlScanner or TXmlParser is
only limited by installed memory.

===============================================================================================
Date        Author Changes
-----------------------------------------------------------------------------------------------
2000-07-27  HeySt  Creation
2000-07-29  HeySt  Used the new TNvpList methods from LibXmlParser
*)

unit Main;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  ComCtrls, StdCtrls, LibXmlComps, LibXmlParser;

type
  TFrmMain = class(TForm)
    XmlScanner: TXmlScanner;
    Label1: TLabel;
    Label2: TLabel;
    EdtFilename: TEdit;
    DlgOpen: TOpenDialog;
    BtnFilename: TButton;
    BtnParse: TButton;
    TreeView: TTreeView;
    procedure BtnParseClick(Sender: TObject);
    procedure BtnFilenameClick(Sender: TObject);
    procedure XmlScannerXmlProlog(Sender: TObject; XmlVersion,
      Encoding: String; Standalone: Boolean);
    procedure XmlScannerPI(Sender: TObject; Target, Content: String; Attributes: TAttrList);
    procedure XmlScannerStartTag(Sender: TObject; TagName: String; Attributes: TAttrList);
    procedure XmlScannerEndTag(Sender: TObject; TagName: String);
    procedure XmlScannerEmptyTag(Sender: TObject; TagName: String; Attributes: TAttrList);
    procedure XmlScannerComment(Sender: TObject; Comment: String);
    procedure XmlScannerContent(Sender: TObject; Content: String);
    procedure XmlScannerDtdRead(Sender: TObject; RootElementName: String);
  private
  public
    CurNode : TTreeNode;
  end;

var
  FrmMain: TFrmMain;

(*
===============================================================================================
implementation
===============================================================================================
*)

implementation

{$R *.DFM}

procedure TFrmMain.BtnParseClick(Sender: TObject);
begin
  // --- Clear TreeView
  TreeView.Items.BeginUpdate;
  TreeView.Items.Clear;

  // --- Load and Scan XML document
  CurNode := NIL;
  XmlScanner.Filename := EdtFilename.Text;
  XmlScanner.Execute;

  // --- Show Tree
  TreeView.Items.EndUpdate;
end;


procedure TFrmMain.BtnFilenameClick(Sender: TObject);
          // Show "Open File" dialog
begin
  IF DlgOpen.Execute THEN BEGIN
    EdtFilename.Text := DlgOpen.Filename;
    BtnParse.SetFocus;
    END;
end;


procedure TFrmMain.XmlScannerXmlProlog(Sender: TObject; XmlVersion, Encoding: String; Standalone: Boolean);
          // This is called when the scanner has read in the XML prolog
          // XmlVersion: XML version number
          // Encoding:   The encoding declared in the Prolog
          // Standalone: TRUE if 'yes' was specified in the Prolog
begin
  TreeView.Items.AddChild (CurNode, 'XML Prolog: Version='+XmlVersion+' Encoding='+Encoding);
end;


procedure TFrmMain.XmlScannerPI(Sender: TObject; Target, Content: String; Attributes: TAttrList);
          // This is called when the scanner has read a Processing Instruction (PI)
begin
  TreeView.Items.AddChild (CurNode, 'Processing Instruction: '+Content);
end;


procedure TFrmMain.XmlScannerStartTag(Sender: TObject; TagName: String; Attributes: TAttrList);
          // This is called when the scanner has read a Start Tag
          // TagName:    Name of the Start Tag (case sensitive)
          // Attributes: List of Attributes (TAttr Objects)
VAR
  i : integer;
begin
  CurNode := TreeView.Items.AddChild (CurNode, 'Element "'+TagName+'"');
  FOR i := 0 TO Attributes.Count-1 DO
    TreeView.Items.AddChild (CurNode, '  * Attribute '+Attributes.Name (i)+'='+Attributes.Value(i));
end;


procedure TFrmMain.XmlScannerEndTag(Sender: TObject; TagName: String);
          // This is called when the scanner has read an End tag
          // TagName: Name of the End Tag (case sensitive)
begin
  IF CurNode <> NIL THEN
    CurNode := CurNode.Parent;
end;


procedure TFrmMain.XmlScannerEmptyTag(Sender: TObject; TagName: String; Attributes: TAttrList);
          // This is called when the scanner has read an XML Empty-Element Tag (e.g. <BR/>
          // TagName: Name of the Tag (case sensitive)
          // Attributes: List of Attributes (TAttr Objects)
VAR
  i : integer;
begin
  CurNode := TreeView.Items.AddChild (CurNode, 'Element "'+TagName+'" (Empty)');
  FOR i := 0 TO Attributes.Count-1 DO
    TreeView.Items.AddChild (CurNode, '  * Attribute '+Attributes.Name (i)+'='+Attributes.Value(i));
  CurNode := CurNode.Parent;
end;


procedure TFrmMain.XmlScannerComment(Sender: TObject; Comment: String);
          // This is called when the scanner has read a Comment
begin
  TreeView.Items.AddChild (CurNode, 'Comment');
end;


procedure TFrmMain.XmlScannerContent(Sender: TObject; Content: String);
          // This is called when the scanner has read element text content
          // The "OnCData" event of XmlScanner also points to this routine
          // Content: The text content
begin
  Content := StringReplace (Content, #13, ' ', [rfReplaceAll]);
  Content := StringReplace (Content, #10, '',  [rfReplaceAll]);
  TreeView.Items.AddChild  (CurNode, Content);
end;

procedure TFrmMain.XmlScannerDtdRead(Sender: TObject;
  RootElementName: String);
begin
  TreeView.Items.AddChild (CurNode, 'DTD: '+RootElementName);
end;

end.



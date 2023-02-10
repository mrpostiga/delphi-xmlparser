(**
===============================================================================================
Name    : LibXmlComps
===============================================================================================
Project : All Projects processing XML documents
===============================================================================================
Subject : XML parser for Delphi's VCL toolbar
===============================================================================================
*)

UNIT LibXmlComps;

INTERFACE

USES
  Classes,
  LibXmlParser;

TYPE
  TXmlScanner = CLASS (TCustomXmlScanner)
                PUBLIC
                  PROPERTY XmlParser;
                  PROPERTY StopParser;
                PUBLISHED
                  PROPERTY Filename;
                  PROPERTY Normalize;
                  PROPERTY OnXmlProlog;
                  PROPERTY OnComment;
                  PROPERTY OnPI;
                  PROPERTY OnDtdRead;
                  PROPERTY OnStartTag;
                  PROPERTY OnEmptyTag;
                  PROPERTY OnEndTag;
                  PROPERTY OnContent;
                  PROPERTY OnCData;
                  PROPERTY OnElement;
                  PROPERTY OnAttList;
                  PROPERTY OnEntity;
                  PROPERTY OnNotation;
                  PROPERTY OnDtdError;
                  PROPERTY OnLoadExternal;
                  PROPERTY OnTranslateEncoding;
                END;

  // The "Easy" XML Scanner leaves out events and properties which you are unlikely to use
  // for "normal" XML files.
  // CDATA sections trigger "OnContent" events
  TEasyXmlScanner = CLASS (TCustomXmlScanner)
                    PROTECTED
                      PROCEDURE WhenCData (Content : STRING); OVERRIDE;
                    PUBLIC
                      PROPERTY XmlParser;
                      PROPERTY StopParser;
                    PUBLISHED
                      PROPERTY Filename;
                      PROPERTY Normalize;
                      PROPERTY OnComment;
                      PROPERTY OnPI;
                      PROPERTY OnStartTag;
                      PROPERTY OnEmptyTag;
                      PROPERTY OnEndTag;
                      PROPERTY OnContent;
                      PROPERTY OnLoadExternal;
                      PROPERTY OnTranslateEncoding;
                    END;

PROCEDURE Register;

(*
===============================================================================================
IMPLEMENTATION
===============================================================================================
*)

IMPLEMENTATION


PROCEDURE Register;
BEGIN
  RegisterComponents ('XML', [TXmlScanner, TEasyXmlScanner]);
END;


(*
===============================================================================================
TEasyXmlScanner
===============================================================================================
*)

PROCEDURE TEasyXmlScanner.WhenCData (Content : STRING);
BEGIN
  INHERITED WhenContent (Content);
END;


(*
===============================================================================================
INITIALIZATION
===============================================================================================
*)

END.


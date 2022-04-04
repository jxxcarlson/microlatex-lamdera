module Evergreen.V234.Parser.Expr exposing (..)

import Evergreen.V234.Parser.Meta


type Expr
    = Expr String (List Expr) Evergreen.V234.Parser.Meta.Meta
    | Text String Evergreen.V234.Parser.Meta.Meta
    | Verbatim String String Evergreen.V234.Parser.Meta.Meta

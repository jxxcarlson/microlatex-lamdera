module Evergreen.V400.Parser.Expr exposing (..)

import Evergreen.V400.Parser.Meta


type Expr
    = Expr String (List Expr) Evergreen.V400.Parser.Meta.Meta
    | Text String Evergreen.V400.Parser.Meta.Meta
    | Verbatim String String Evergreen.V400.Parser.Meta.Meta

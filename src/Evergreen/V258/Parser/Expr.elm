module Evergreen.V258.Parser.Expr exposing (..)

import Evergreen.V258.Parser.Meta


type Expr
    = Expr String (List Expr) Evergreen.V258.Parser.Meta.Meta
    | Text String Evergreen.V258.Parser.Meta.Meta
    | Verbatim String String Evergreen.V258.Parser.Meta.Meta

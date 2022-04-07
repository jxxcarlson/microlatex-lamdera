module Evergreen.V277.Parser.Expr exposing (..)

import Evergreen.V277.Parser.Meta


type Expr
    = Expr String (List Expr) Evergreen.V277.Parser.Meta.Meta
    | Text String Evergreen.V277.Parser.Meta.Meta
    | Verbatim String String Evergreen.V277.Parser.Meta.Meta

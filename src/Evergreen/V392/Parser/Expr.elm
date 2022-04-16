module Evergreen.V392.Parser.Expr exposing (..)

import Evergreen.V392.Parser.Meta


type Expr
    = Expr String (List Expr) Evergreen.V392.Parser.Meta.Meta
    | Text String Evergreen.V392.Parser.Meta.Meta
    | Verbatim String String Evergreen.V392.Parser.Meta.Meta

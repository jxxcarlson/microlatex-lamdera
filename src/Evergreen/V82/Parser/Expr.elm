module Evergreen.V82.Parser.Expr exposing (..)

import Evergreen.V82.Parser.Meta


type Expr
    = Expr String (List Expr) Evergreen.V82.Parser.Meta.Meta
    | Text String Evergreen.V82.Parser.Meta.Meta
    | Verbatim String String Evergreen.V82.Parser.Meta.Meta

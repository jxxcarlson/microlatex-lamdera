module Evergreen.V226.Parser.Expr exposing (..)

import Evergreen.V226.Parser.Meta


type Expr
    = Expr String (List Expr) Evergreen.V226.Parser.Meta.Meta
    | Text String Evergreen.V226.Parser.Meta.Meta
    | Verbatim String String Evergreen.V226.Parser.Meta.Meta

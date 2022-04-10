module Evergreen.V334.Parser.Expr exposing (..)

import Evergreen.V334.Parser.Meta


type Expr
    = Expr String (List Expr) Evergreen.V334.Parser.Meta.Meta
    | Text String Evergreen.V334.Parser.Meta.Meta
    | Verbatim String String Evergreen.V334.Parser.Meta.Meta

module Evergreen.V24.Parser.Expr exposing (..)

import Evergreen.V24.Parser.Meta


type Expr
    = Expr String (List Expr) Evergreen.V24.Parser.Meta.Meta
    | Text String Evergreen.V24.Parser.Meta.Meta
    | Verbatim String String Evergreen.V24.Parser.Meta.Meta
    | Error String

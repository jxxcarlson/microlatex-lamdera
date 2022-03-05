module Evergreen.V72.Parser.Expr exposing (..)

import Evergreen.V72.Parser.Meta


type Expr
    = Expr String (List Expr) Evergreen.V72.Parser.Meta.Meta
    | Text String Evergreen.V72.Parser.Meta.Meta
    | Verbatim String String Evergreen.V72.Parser.Meta.Meta
    | Error String

module Evergreen.V55.Parser.Expr exposing (..)

import Evergreen.V55.Parser.Meta


type Expr
    = Expr String (List Expr) Evergreen.V55.Parser.Meta.Meta
    | Text String Evergreen.V55.Parser.Meta.Meta
    | Verbatim String String Evergreen.V55.Parser.Meta.Meta
    | Error String

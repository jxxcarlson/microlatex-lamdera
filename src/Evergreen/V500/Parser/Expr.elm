module Evergreen.V500.Parser.Expr exposing (..)

import Evergreen.V500.Parser.Meta


type Expr
    = Expr String (List Expr) Evergreen.V500.Parser.Meta.Meta
    | Text String Evergreen.V500.Parser.Meta.Meta
    | Verbatim String String Evergreen.V500.Parser.Meta.Meta

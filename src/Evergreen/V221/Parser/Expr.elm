module Evergreen.V221.Parser.Expr exposing (..)

import Evergreen.V221.Parser.Meta


type Expr
    = Expr String (List Expr) Evergreen.V221.Parser.Meta.Meta
    | Text String Evergreen.V221.Parser.Meta.Meta
    | Verbatim String String Evergreen.V221.Parser.Meta.Meta

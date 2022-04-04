module Evergreen.V236.Parser.Expr exposing (..)

import Evergreen.V236.Parser.Meta


type Expr
    = Expr String (List Expr) Evergreen.V236.Parser.Meta.Meta
    | Text String Evergreen.V236.Parser.Meta.Meta
    | Verbatim String String Evergreen.V236.Parser.Meta.Meta

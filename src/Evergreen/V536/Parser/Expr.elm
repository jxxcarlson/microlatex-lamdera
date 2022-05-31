module Evergreen.V536.Parser.Expr exposing (..)

import Evergreen.V536.Parser.Meta


type Expr
    = Expr String (List Expr) Evergreen.V536.Parser.Meta.Meta
    | Text String Evergreen.V536.Parser.Meta.Meta
    | Verbatim String String Evergreen.V536.Parser.Meta.Meta

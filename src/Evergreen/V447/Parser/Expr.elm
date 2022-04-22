module Evergreen.V447.Parser.Expr exposing (..)

import Evergreen.V447.Parser.Meta


type Expr
    = Expr String (List Expr) Evergreen.V447.Parser.Meta.Meta
    | Text String Evergreen.V447.Parser.Meta.Meta
    | Verbatim String String Evergreen.V447.Parser.Meta.Meta

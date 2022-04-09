module Evergreen.V310.Parser.Expr exposing (..)

import Evergreen.V310.Parser.Meta


type Expr
    = Expr String (List Expr) Evergreen.V310.Parser.Meta.Meta
    | Text String Evergreen.V310.Parser.Meta.Meta
    | Verbatim String String Evergreen.V310.Parser.Meta.Meta

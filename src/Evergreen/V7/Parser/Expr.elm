module Evergreen.V7.Parser.Expr exposing (..)

import Evergreen.V7.Parser.Token


type Expr
    = Expr String (List Expr) Evergreen.V7.Parser.Token.Meta
    | Text String Evergreen.V7.Parser.Token.Meta
    | Verbatim String String Evergreen.V7.Parser.Token.Meta
    | Error String

module Evergreen.V449.Authentication exposing (..)

import Dict
import Evergreen.V449.Credentials
import Evergreen.V449.User


type alias Username =
    String


type alias UserData =
    { user : Evergreen.V449.User.User
    , credentials : Evergreen.V449.Credentials.Credentials
    }


type alias AuthenticationDict =
    Dict.Dict Username UserData

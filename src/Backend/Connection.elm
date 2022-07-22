module Backend.Connection exposing (getConnectionData, getUsersAndOnlineStatus_)

import Authentication
import Dict
import Effect.Lamdera
import Types exposing (BackendModel, ConnectionDict)


getConnectionData : BackendModel -> List String
getConnectionData model =
    model.connectionDict
        |> Dict.toList
        |> List.map (\( u, data ) -> u ++ ":: " ++ String.fromInt (List.length data) ++ " :: " ++ connectionDataListToString data)


truncateMiddle : Int -> Int -> String -> String
truncateMiddle dropBoth dropRight str =
    String.left dropBoth str ++ "..." ++ String.right dropBoth (String.dropRight dropRight str)


connectionDataListToString : List Types.ConnectionData -> String
connectionDataListToString list =
    list |> List.map connectionDataToString |> String.join "; "


connectionDataToString : Types.ConnectionData -> String
connectionDataToString { session, client } =
    "(" ++ truncateMiddle 2 0 (Effect.Lamdera.sessionIdToString session) ++ ", " ++ truncateMiddle 2 2 (Effect.Lamdera.clientIdToString client) ++ ")"


getUsersAndOnlineStatus_ : Authentication.AuthenticationDict -> ConnectionDict -> List ( String, Int )
getUsersAndOnlineStatus_ authenticationDict connectionDict =
    let
        isConnected username =
            case Dict.get username connectionDict of
                Nothing ->
                    0

                Just data ->
                    List.length data
    in
    List.map (\u -> ( u, isConnected u )) (Dict.keys authenticationDict)

module Evergreen.V400.Compiler.DifferentialParser exposing (..)

import Evergreen.V400.Compiler.AbstractDifferentialParser
import Evergreen.V400.Compiler.Acc
import Evergreen.V400.Parser.Block
import Evergreen.V400.Parser.PrimitiveBlock
import Tree


type alias EditRecord =
    Evergreen.V400.Compiler.AbstractDifferentialParser.EditRecord (Tree.Tree Evergreen.V400.Parser.PrimitiveBlock.PrimitiveBlock) (Tree.Tree Evergreen.V400.Parser.Block.ExpressionBlock) Evergreen.V400.Compiler.Acc.Accumulator

module Evergreen.V195.Compiler.DifferentialParser exposing (..)

import Evergreen.V195.Compiler.AbstractDifferentialParser
import Evergreen.V195.Compiler.Acc
import Evergreen.V195.Parser.Block
import Evergreen.V195.Parser.PrimitiveBlock
import Tree


type alias EditRecord =
    Evergreen.V195.Compiler.AbstractDifferentialParser.EditRecord (Tree.Tree Evergreen.V195.Parser.PrimitiveBlock.PrimitiveBlock) (Tree.Tree Evergreen.V195.Parser.Block.ExpressionBlock) Evergreen.V195.Compiler.Acc.Accumulator

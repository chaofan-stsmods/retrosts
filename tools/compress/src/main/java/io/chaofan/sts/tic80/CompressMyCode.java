package io.chaofan.sts.tic80;

import io.chaofan.util.bitstream.BigEndianBitOutputStream;

import java.io.BufferedReader;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.*;
import java.util.function.Consumer;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.stream.Collectors;

public class CompressMyCode {
    public static void main(String[] args) throws IOException {
        String basePath = args.length > 0 ? args[0] : "C:\\Users\\Chaofan\\AppData\\Roaming\\com.nesbox.tic\\TIC-80\\myproj\\sts\\out";
        String path = basePath + "\\out.lua";
        List<String> prefixLines = new BufferedReader(new InputStreamReader(CompressMyCode.class.getResourceAsStream("/prefix.lua")))
                .lines().collect(Collectors.toList());
        List<String> lines = Files.readAllLines(Paths.get(path));
        int originalLength = lines.stream().mapToInt(String::length).reduce(Integer::sum).orElse(0) + lines.size();

        List<String> suffixLines = new ArrayList<>();
        boolean readSuffix = false;
        boolean inCommentBlock = false;
        for (int i = 0; i < lines.size(); i++) {
            String line = lines.get(i);
            if (line.contains("-- <TILES>")) {
                readSuffix = true;
            }
            if (readSuffix) {
                suffixLines.add(line);
            }
            line = line.trim();
            if (line.startsWith("--[[")) {
                inCommentBlock = true;
            }
            if (line.startsWith("]]--")) {
                inCommentBlock = false;
                line = "";
            }
            if (inCommentBlock) {
                line = "";
            }
            if (line.startsWith("--")) {
                line = "";
            }
            line = line
                    .replaceAll("('(?:\\\\.|[^\\\\'])*')|(\"(?:\\\\.|[^\\\\\"])*\")| ?([,+=\\-*/()\\[\\]{}:<>.#]) ?", "$1$2$3");
            lines.set(i, line);
        }
        lines = lines.stream().filter(l -> l.length() > 0).collect(Collectors.toList());
        String code = String.join("\n",lines);

        int suffixLength = suffixLines.stream().mapToInt(String::length).reduce(Integer::sum).orElse(0) + suffixLines.size();
        System.out.println("Original code length: " + (originalLength - suffixLength));
        System.out.println("Code remove space length: " + code.length());

        TreeNode[] rootContainer = new TreeNode[1];
        byte[] huffmanResult = huffman(code, rootContainer, false);
        TreeNode root = rootContainer[0];
        String base64String = new String(Base64.getEncoder().encode(huffmanResult));

        Map<String, TreeNode> wordCodes = new HashMap<>();
        root.visit(t -> wordCodes.put(t.name, t));

        StringBuilder sb = new StringBuilder();
        sb.append(String.join("\n",prefixLines));
        sb.append("\nloadDecode(\n");
        /*
        int lineSize = 200;
        for (int i = 0, j = Math.min(lineSize, base64String.length());
             i < base64String.length();
             i = j, j = Math.min(j + lineSize, base64String.length())) {
            sb.append("'");
            sb.append(base64String, i, j);
            sb.append("'..\n");
        }
        sb.setLength(sb.length() - 3);
        /*/
        sb.append("'");
        sb.append(base64String);
        sb.append("'");
        //*/
        sb.append(",\n'");
        sb.append(root.toCompressedLuaTree());
        sb.append("'\n)\n");
        System.out.println("Final code length: " + sb.length());
        sb.append(String.join("\n",suffixLines));

        System.out.println("Compressed code length: " + base64String.length());
        System.out.println("Num words: " + wordCodes.size());
        System.out.println("Num tree nodes: " + root.size());
        System.out.println("Num tree depth: " + root.depth());
        System.out.println("Longest word length: " + root.longestWord());
        System.out.println("Sum word length: " + root.wordSize());

        Files.write(Paths.get(basePath + "\\compressed.lua"), sb.toString().getBytes(StandardCharsets.UTF_8));
        Files.write(Paths.get(basePath + "\\uncompressed.lua"), code.getBytes(StandardCharsets.UTF_8));
    }

    public static byte[] huffman(String code, TreeNode[] rootContainer, boolean eachChar) throws IOException {
        Map<String, Integer> words = new HashMap<>();
        if (eachChar) {
            for (int i = 0, len = code.length(); i < len; i++) {
                words.merge(String.valueOf(code.charAt(i)), 1, Integer::sum);
            }
        } else {
            visitCode(code, s -> words.merge(s, 1, Integer::sum));
        }
        words.merge(" ", 1, Integer::sum);

        List<TreeNode> dict = words.entrySet().stream()
                .map(e -> new TreeNode(e.getKey(), e.getValue()))
                .collect(Collectors.toList());
        TreeSet<TreeNode> treeNodes = new TreeSet<>((a, b) -> {
            int i = Integer.compare(a.value, b.value);
            if (i == 0) {
                return Integer.compare(a.index, b.index);
            }
            return i;
        });
        treeNodes.addAll(dict);
        while (treeNodes.size() > 1) {
            TreeNode node1 = treeNodes.pollFirst();
            TreeNode node2 = treeNodes.pollFirst();
            assert node1 != null;
            assert node2 != null;
            TreeNode parent = new TreeNode(node1, node2);
            treeNodes.add(parent);
        }

        TreeNode root = treeNodes.first();

        root.fillCode(0, 0);
        Map<String, TreeNode> wordCodes = new HashMap<>();
        root.visit(t -> wordCodes.put(t.name, t));

        ByteArrayOutputStream bout = new ByteArrayOutputStream();
        BigEndianBitOutputStream out = new BigEndianBitOutputStream(bout);
        int[] bitLength = new int[] { 0 };
        if (eachChar) {
            for (int i = 0, len = code.length(); i < len; i++) {
                TreeNode t = wordCodes.get(String.valueOf(code.charAt(i)));
                try {
                    out.write(t.code, t.codeLength);
                    bitLength[0] += t.codeLength;
                } catch (IOException ignored) {
                }
            }
        } else {
            visitCode(code, s -> {
                TreeNode t = wordCodes.get(s);
                try {
                    out.write(t.code, t.codeLength);
                    bitLength[0] += t.codeLength;
                } catch (IOException ignored) {
                }
            });
        }

        TreeNode space = wordCodes.get(" ");
        int byteLength = (bitLength[0] + 23) / 24 * 3;
        int remaining = byteLength * 8 - bitLength[0];
        while (remaining >= 0) {
            out.write(space.code, space.codeLength);
            remaining -= space.codeLength;
        }

        rootContainer[0] = root;
        return bout.toByteArray();
    }

    public static void visitCode(String code, Consumer<String> callback) {
        Pattern wordPattern = Pattern.compile("[0-9]|[a-zA-Z_][0-9a-zA-Z_]*");
        int start = 0;
        Matcher matcher = wordPattern.matcher(code);
        while (matcher.find()) {
            int matcherStart = matcher.start();
            int matcherEnd = matcher.end();
            for (int i = start; i < matcherStart; i++) {
                callback.accept(String.valueOf(code.charAt(i)));
            }
            callback.accept(matcher.group());
            start = matcherEnd;
        }

        int codeLength = code.length();
        for (int i = start; i < codeLength; i++) {
            callback.accept(String.valueOf(code.charAt(i)));
        }
    }

    public static class TreeNode {
        static int nextIndex = 0;

        int index;
        String name;
        int value;
        TreeNode left;
        TreeNode right;
        int code;
        int codeLength;

        private TreeNode(String name, int value) {
            this.name = name;
            this.value = value;
            this.index = ++nextIndex;
        }

        private TreeNode(TreeNode left, TreeNode right) {
            this.value = left.value + right.value;
            this.name = "TreeNode(" + this.value + ")";
            this.left = left;
            this.right = right;
            this.index = ++nextIndex;
        }

        public int depth() {
            return left == null ? 1 : Math.max(left.depth(), right.depth()) + 1;
        }

        public int size() {
            return left == null ? 1 : left.size() + right.size() + 1;
        }

        public int longestWord() {
            return left == null ? this.name.length() : Math.max(left.longestWord(), right.longestWord());
        }

        public int wordSize() {
            return left == null ? this.name.length() : Integer.sum(left.wordSize(), right.wordSize());
        }

        public void fillCode(int prefix, int prefixLength) {
            if (left == null) {
                code = prefix;
                codeLength = prefixLength;
            } else {
                left.fillCode(prefix << 1, prefixLength + 1);
                right.fillCode((prefix << 1) + 1, prefixLength + 1);
            }
        }

        public void visit(Consumer<TreeNode> callback) {
            if (left == null) {
                callback.accept(this);
            } else {
                left.visit(callback);
                right.visit(callback);
            }
        }

        @Override
        public String toString() {
            if (this.left != null) {
                return "TreeNode(" + left + "," + right + ")";
            } else {
                return "TreeNode(" + name + ")";
            }
        }

        public String toLuaTree() {
            if (this.left != null) {
                return String.format("{%s,%s}", this.left.toLuaTree(), this.right.toLuaTree());
            } else {
                return "'" + name.replace("\\", "\\\\").replace("'", "\\'").replace("\n", "\\n") + "'";
            }
        }

        public String toCompressedLuaTree() {
            if (this.left != null) {
                return String.format("0%s%s", this.left.toCompressedLuaTree(), this.right.toCompressedLuaTree());
            } else {
                return ((char)('0' + this.name.length()) + this.name).replace("\\", "\\\\").replace("'", "\\'").replace("\n", "\\n");
            }
        }
    }
}

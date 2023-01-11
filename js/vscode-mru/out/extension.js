"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.activate = void 0;
const vscode = require("vscode");
const node_fetch_1 = require("node-fetch");
const visited = {};
function activate(context) {
    vscode.workspace.onDidOpenTextDocument(document => {
        postData(document);
    });
    vscode.window.onDidChangeActiveTextEditor(editor => {
        postData(editor?.document);
    });
    vscode.window.onDidChangeTextEditorSelection(({ textEditor }) => {
        const path = textEditor.document.uri.path;
        visited[path] = {
            line: textEditor.selection.active.line,
            column: textEditor.selection.active.character
        };
        // fs.writeFileSync('/tmp/visited.json', JSON.stringify(visited));
    });
}
exports.activate = activate;
function postData(document) {
    const path = document?.uri?.path;
    if (!path || !visited[path]) {
        return;
    }
    ;
    const data = {
        ...visited[path],
        "filepath": path,
        "event": "fileFocus"
    };
    // fs.writeFileSync('/tmp/a.json', JSON.stringify(data));
    (0, node_fetch_1.default)("http://localhost:2021/mru", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(data)
    })
        .then((response) => response.json())
        .then((data) => console.log("Success:", data))
        .catch((error) => console.error("Error:", error));
}
//
//
//
//
//
//
// The module 'vscode' contains the VS Code extensibility API
// Import the module and reference it with the alias vscode in your code below
// import * as vscode from 'vscode';
// // This method is called when your extension is activated
// // Your extension is activated the very first time the command is executed
// export function activate(context: vscode.ExtensionContext) {
// 	// Use the console to output diagnostic information (console.log) and errors (console.error)
// 	// This line of code will only be executed once when your extension is activated
// 	console.log('Congratulations, your extension "vscode-mru" is now active!');
// 	// The command has been defined in the package.json file
// 	// Now provide the implementation of the command with registerCommand
// 	// The commandId parameter must match the command field in package.json
// 	let disposable = vscode.commands.registerCommand('vscode-mru.helloWorld', () => {
// 		// The code you place here will be executed every time your command is executed
// 		// Display a message box to the user
// 		vscode.window.showInformationMessage('Hello World from vscode-mru!');
// 	});
// 	context.subscriptions.push(disposable);
// }
// // This method is called when your extension is deactivated
// export function deactivate() {}
//# sourceMappingURL=extension.js.map
import * as vscode from 'vscode';
import * as fs from 'fs';
import fetch from 'node-fetch';
import {text} from 'stream/consumers';

type Visited = Record<string, {line: number, column: number}>;
const visited: Visited = {};
export function activate(context: vscode.ExtensionContext) {
  vscode.workspace.onDidOpenTextDocument(document => {
    postData(document);
  });

  vscode.window.onDidChangeActiveTextEditor(editor => {
    postData(editor?.document);
  });
  vscode.window.onDidChangeTextEditorSelection(({textEditor}) => {
    const path = textEditor.document.uri.path;
    visited[path] = {
      line: textEditor.selection.active.line,
      column: textEditor.selection.active.character
    };
    // fs.writeFileSync('/tmp/visited.json', JSON.stringify(visited));
  });
}

function postData(document?: vscode.TextDocument) {
  const path = document?.uri?.path;
  if(!path || !visited[path]) {return;};
  const data = {
    ...visited[path],
    "filepath": path,
    "event": "fileFocus"
  };

  // fs.writeFileSync('/tmp/a.json', JSON.stringify(data));
  fetch("http://localhost:2021/mru", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(data)
  })
    .then((response: {json: () => any;}) => response.json())
    .then((data: any) => console.log("Success:", data))
    .catch((error: any) => console.error("Error:", error));
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

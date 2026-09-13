'use strict'

const vscode = require('vscode')

function quoteShell(value) {
  if (process.platform === 'win32') {
    return `"${value.replaceAll('"', '""')}"`
  }
  return `'${value.replaceAll("'", "'\\''")}'`
}

async function execute(command) {
  const editor = vscode.window.activeTextEditor
  if (!editor || editor.document.languageId !== 'nusa') {
    void vscode.window.showErrorMessage('Buka berkas .nusa sebelum menjalankan perintah ini.')
    return
  }

  if (editor.document.isDirty) {
    const saved = await editor.document.save()
    if (!saved) {
      void vscode.window.showErrorMessage('Berkas NusaCode gagal disimpan.')
      return
    }
  }

  const runtime = vscode.workspace
    .getConfiguration('nusacode')
    .get('runtimePath', 'nusa')
  const terminal = vscode.window.createTerminal({ name: 'NusaCode' })
  const file = editor.document.uri.fsPath
  terminal.show(true)
  terminal.sendText(`${quoteShell(runtime)} ${command} ${quoteShell(file)}`, true)
}

function activate(context) {
  context.subscriptions.push(
    vscode.commands.registerCommand('nusacode.runFile', () => execute('run')),
    vscode.commands.registerCommand('nusacode.checkFile', () => execute('check')),
  )
}

function deactivate() {}

module.exports = { activate, deactivate }

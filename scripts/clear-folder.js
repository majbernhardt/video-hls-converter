const fs = require('fs')
const path = require('path')

function clearFolder(folder) {
	if (!fs.existsSync(folder)) {
		console.log(`Папка ${folder} не найдена`)
		return
	}

	const entries = fs.readdirSync(folder, { withFileTypes: true })

	for (const entry of entries) {
		const fullPath = path.join(folder, entry.name)

		if (entry.isDirectory()) {
			clearFolder(fullPath)
			// Удаляем пустые папки
			if (fs.readdirSync(fullPath).length === 0) {
				fs.rmdirSync(fullPath)
			}
		} else if (entry.name !== '.gitignore') {
			fs.rmSync(fullPath)
		}
	}
}

const folder = process.argv[2]

if (!folder) {
	console.error('Ошибка: нужно указать папку для очистки, например "node scripts/clear-folder.js video"')
	process.exit(1)
}

clearFolder(folder)
console.log(`Папка "${folder}" очищена`)

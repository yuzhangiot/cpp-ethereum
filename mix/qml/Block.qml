import QtQuick 2.2
import QtQuick.Controls 1.1
import QtQuick.Controls.Styles 1.1
import QtQuick.Dialogs 1.1
import QtQuick.Layouts 1.1
import Qt.labs.settings 1.0
import "js/Debugger.js" as Debugger
import "js/ErrorLocationFormater.js" as ErrorLocationFormater
import "."

ColumnLayout
{
	id: root
	property variant transactions
	property string status
	property int number
	property int blockWidth: Layout.preferredWidth - statusWidth - horizontalMargin
	property int horizontalMargin: 10
	property int trHeight: 35
	spacing: 0
	property int openedTr: 0
	property int blockIndex
	property variant scenario
	property string labelColor: "#414141"

	function calculateHeight()
	{
		if (transactions)
		{
			if (index >= 0)
				return trHeight + trHeight * transactions.count + openedTr
			else
				return trHeight
		}
		else
			return trHeight
	}

	onOpenedTrChanged:
	{
		Layout.preferredHeight = calculateHeight()
		height = calculateHeight()
	}

	DebuggerPaneStyle {
		id: dbgStyle
	}

	Rectangle
	{
		id: top
		Layout.preferredWidth: blockWidth
		height: 10
		anchors.bottom: rowHeader.top
		color: "#DEDCDC"
		radius: 15
		anchors.left: parent.left
		anchors.leftMargin: statusWidth
		anchors.bottomMargin: -5
	}

	RowLayout
	{
		Layout.preferredHeight: trHeight
		Layout.preferredWidth: blockWidth
		id: rowHeader
		spacing: 0
		Rectangle
		{
			Layout.preferredWidth: blockWidth
			Layout.preferredHeight: trHeight
			color: "#DEDCDC"
			anchors.left: parent.left
			anchors.leftMargin: statusWidth
			Label {
				anchors.verticalCenter: parent.verticalCenter
				anchors.left: parent.left
				anchors.leftMargin: horizontalMargin
				font.pointSize: dbgStyle.absoluteSize(1)
				color: "#adadad"
				text:
				{
					if (number === -2)
						return qsTr("STARTING PARAMETERS")
					else if (status === "mined")
						return qsTr("BLOCK") + " " + number
					else
						return qsTr("PENDING TRANSACTIONS")
				}
			}

			Label
			{
				text: qsTr("EDIT")
				color:  "#1397da"
				anchors.verticalCenter: parent.verticalCenter
				anchors.right: parent.right
				anchors.rightMargin: 14
				MouseArea
				{
					anchors.fill: parent
					onClicked:
					{
						// load edit block panel
					}
				}
			}
		}
	}

	Repeater // List of transactions
	{
		id: transactionRepeater
		model: transactions
		RowLayout
		{
			id: rowTransaction
			Layout.preferredHeight: trHeight
			spacing: 0
			function displayContent()
			{
				logsText.text = ""
				if (index >= 0 && transactions.get(index).logs && transactions.get(index).logs.count)
				{
					for (var k = 0; k < transactions.get(index).logs.count; k++)
					{
						var log = transactions.get(index).logs.get(k)
						if (log.name)
							logsText.text += log.name + ":\n"
						else
							logsText.text += "log:\n"

						if (log.param)
							for (var i = 0; i < log.param.count; i++)
							{
								var p = log.param.get(i)
								logsText.text += p.name + " = " + p.value + " - indexed:" + p.indexed + "\n"
							}
						else {
							logsText.text += "From : " + log.address + "\n"
						}
					}
					logsText.text += "\n\n"
				}
				rowDetailedContent.visible = !rowDetailedContent.visible
			}

			Rectangle
			{
				id: trSaveStatus
				Layout.preferredWidth: statusWidth
				Layout.preferredHeight: parent.height
				color: "transparent"
				anchors.top: parent.top
				property bool saveStatus
				Image {
					anchors.top: parent.top
					anchors.left: parent.left
					anchors.leftMargin: -9
					anchors.topMargin: -9
					id: saveStatusImage
					source: "qrc:/qml/img/recyclediscard@2x.png"
					width: statusWidth + 20
					fillMode: Image.PreserveAspectFit
				}

				Component.onCompleted:
				{
					if (index >= 0)
						saveStatus = transactions.get(index).saveStatus
				}

				onSaveStatusChanged:
				{
					if (saveStatus)
						saveStatusImage.source = "qrc:/qml/img/recyclekeep@2x.png"
					else
						saveStatusImage.source = "qrc:/qml/img/recyclediscard@2x.png"

					if (index >= 0)
						transactions.get(index).saveStatus = saveStatus
				}

				MouseArea {
					id: statusMouseArea
					anchors.fill: parent
					onClicked:
					{
						parent.saveStatus = !parent.saveStatus
					}
				}
			}

			Rectangle
			{
				Layout.preferredWidth: blockWidth
				Layout.preferredHeight: parent.height
				color: "#DEDCDC"
				id: rowContentTr
				anchors.top: parent.top

				MouseArea
				{
					anchors.fill: parent
					onDoubleClicked:
					{
						transactionDialog.stateAccounts = scenario.accounts
						transactionDialog.execute = false
						transactionDialog.open(index, blockIndex,  transactions.get(index))
					}
				}

				ColumnLayout
				{
					anchors.top: parent.top
					width: parent.width
					spacing: 20
					RowLayout
					{
						anchors.top: parent.top
						Layout.fillWidth: true
						Rectangle
						{
							Layout.preferredWidth: fromWidth
							anchors.left: parent.left
							anchors.leftMargin: horizontalMargin
							Text
							{
								id: hash
								width: parent.width - 30
								elide: Text.ElideRight
								anchors.verticalCenter: parent.verticalCenter
								maximumLineCount: 1
								color: labelColor
								font.pointSize: dbgStyle.absoluteSize(1)
								font.bold: true
								text: {
									if (index >= 0)
										return transactions.get(index).sender
									else
										return ""
								}
							}
						}


						Rectangle
						{
							Layout.preferredWidth: toWidth
							Text
							{
								id: func
								text: {
									if (index >= 0)
										parent.parent.userFrienldyToken(transactions.get(index).label)
									else
										return ""
								}
								elide: Text.ElideRight
								anchors.verticalCenter: parent.verticalCenter
								color: labelColor
								font.pointSize: dbgStyle.absoluteSize(1)
								font.bold: true
								maximumLineCount: 1
								width: parent.width
							}
						}



						function userFrienldyToken(value)
						{
							if (value && value.indexOf("<") === 0)
							{
								if (value.split("> ")[1] === " - ")
									return value.split(" - ")[0].replace("<", "")
								else
									return value.split(" - ")[0].replace("<", "") + "." + value.split("> ")[1] + "()";
							}
							else
								return value
						}

						Rectangle
						{
							Layout.preferredWidth: valueWidth
							Text
							{
								id: returnValue
								elide: Text.ElideRight
								anchors.verticalCenter: parent.verticalCenter
								maximumLineCount: 1
								color: labelColor
								font.bold: true
								font.pointSize: dbgStyle.absoluteSize(1)
								width: parent.width -30
								text: {
									if (index >= 0 && transactions.get(index).returned)
										return transactions.get(index).returned
									else
										return ""
								}
							}
						}

						Rectangle
						{
							Layout.preferredWidth: logsWidth
							Layout.preferredHeight: trHeight - 10
							width: logsWidth
							color: "transparent"
							Text
							{
								id: logs
								anchors.left: parent.left
								anchors.verticalCenter: parent.verticalCenter
								anchors.leftMargin: 10
								color: labelColor
								font.bold: true
								font.pointSize: dbgStyle.absoluteSize(1)
								text: {
									if (index >= 0 && transactions.get(index).logs && transactions.get(index).logs.count)
										return transactions.get(index).logs.count
									else
										return ""
								}
							}
							MouseArea {
								anchors.fill: parent
								onClicked: {
									rowTransaction.displayContent();
								}
							}
						}
					}

					RowLayout
					{
						id: rowDetailedContent
						visible: false
						Layout.preferredHeight:{
							if (index >= 0 && transactions.get(index).logs)
								return 100 * transactions.get(index).logs.count
							else
								return 100
						}
						onVisibleChanged:
						{
							var lognb = transactions.get(index).logs.count
							if (visible)
							{
								rowContentTr.Layout.preferredHeight = trHeight + 100 * lognb
								openedTr += 100 * lognb
							}
							else
							{
								rowContentTr.Layout.preferredHeight = trHeight
								openedTr -= 100 * lognb
							}
						}

						Text {
							anchors.left: parent.left
							anchors.leftMargin: horizontalMargin
							id: logsText
						}
					}
				}
			}

			Rectangle
			{
				width: debugActionWidth
				height: trHeight
				anchors.left: rowContentTr.right
				anchors.topMargin: -6
				anchors.top: rowContentTr.top
				anchors.leftMargin: -50
				color: "transparent"

				Image {
					id: debugImg
					source: "qrc:/qml/img/rightarrow@2x.png"
					width: debugActionWidth
					fillMode: Image.PreserveAspectFit
					anchors.verticalCenter: parent.verticalCenter
					anchors.horizontalCenter: parent.horizontalCenter
					visible: transactions.get(index).recordIndex !== undefined
				}
				MouseArea
				{
					anchors.fill: parent
					onClicked:
					{
						if (transactions.get(index).recordIndex !== undefined)
						{
							debugTrRequested = [ blockIndex, index ]
							clientModel.debugRecord(transactions.get(index).recordIndex);
						}
					}
				}
			}
		}
	}

	Rectangle
	{
		id: right
		Layout.preferredWidth: blockWidth
		height: 10
		anchors.top: parent.bottom
		anchors.topMargin: 5
		color: "#DEDCDC"
		radius: 15
		anchors.left: parent.left
		anchors.leftMargin: statusWidth
	}
}


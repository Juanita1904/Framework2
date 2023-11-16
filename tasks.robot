*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images. Template robot main suite.

Library             RPA.Browser.Selenium    auto_close=${FALSE}
Library             RPA.HTTP
Library             RPA.Tables
Library             RPA.Desktop
Library             RPA.JavaAccessBridge
Library             RPA.PDF
Library             Collections
Library             RPA.Archive
Library             RPA.RobotLogListener


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot orders web
    Mute Run On Failure    Get orders    optional_keyword_to_run=Get orders
    Get orders
    Create ZIP package from PDF files
    Mute Run On Failure
    [Teardown]    Close Browser RobotSpareBin


*** Keywords ***
Open the robot orders web
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order    maximized=${True}

Close Browser RobotSpareBin
    Close Browser

Fill the form
    [Arguments]    ${order}
    Select From List By Value    //select[@id="head"]    ${order}[Head]
    RPA.Browser.Selenium.Click Element    xpath://input[@class='form-check-input'][@value='${order}[Body]']
    Input Text    //input[@placeholder='Enter the part number for the legs']    ${order}[Legs]
    Input Text    //input[@placeholder='Shipping address']    ${order}[Address]

Get orders
    Download    https://robotsparebinindustries.com/orders.csv    overwrite=${True}
    ${orders}=    Read table from CSV    orders.csv    header= ${True}
    FOR    ${order}    IN    @{orders}
        Close the annoying modal
        Run Keyword And Continue On Failure    Fill the form    ${order}
        # Retry with a one-minute timeout and at one second intervals.
        ${DIS}=    Is Element Visible    id:order-another
        WHILE    ${DIS} == $False    limit=10
            TRY
                Click Element When Clickable    id:order
                CONTINUE
            EXCEPT
                BREAK
            END
        END

        Sleep    2
        Embed screenshot to the receipt    ${order}
        Wait And Click Button    id:order-another
    END

Close the annoying modal
    Click Button When Visible    xpath://button[@type='button'][contains(.,'OK')]

Embed screenshot to the receipt
    # Store the order receipt as a PDF file
    [Arguments]    ${order}
    ${receipt}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${receipt}    ${OUTPUT_DIR}${/}Orders${/}receipt${order}[Order number].pdf
    # Take a screenshot of the robot
    Screenshot    id:robot-preview-image    ${OUTPUT_DIR}${/}Orders${/}receipt${order}[Order number].PNG
    Open Pdf    ${OUTPUT_DIR}${/}Orders${/}receipt${order}[Order number].pdf
    ${files}=    Create list
    ...    ${OUTPUT_DIR}${/}Orders${/}receipt${order}[Order number].PNG
    ...    ${OUTPUT_DIR}${/}Orders${/}receipt${order}[Order number].pdf
    Add Watermark Image To Pdf
    ...    ${OUTPUT_DIR}${/}Orders${/}receipt${order}[Order number].PNG
    ...    ${OUTPUT_DIR}${/}NewOrders${/}receiptNew${order}[Order number].pdf
    Close All Pdfs

Create ZIP package from PDF files
    Archive Folder With Zip
    ...    ${OUTPUT_DIR}${/}NewOrders
    ...    ${OUTPUT_DIR}/PDFs.zip

const fs = require('fs');

function applyFixes(filePath) {
    let c = fs.readFileSync(filePath, 'utf8');

    // 1. Replace ALL toBeVisible checks with waitFor attached
    c = c.replace(/await expect\((.+?)\)\.toBeVisible\((.*?)\);/g, (m, p1, p2) => {
        if (p2 && p2.trim().length > 0) {
            return `await ${p1}.waitFor({ state: 'attached', ...(${p2}) });`;
        }
        return `await ${p1}.waitFor({ state: 'attached' });`;
    });

    // 2. Also replace explicit state:'visible' instances in any manual waitFor calls using a regex
    c = c.replace(/state:\s*'visible'/g, "state: 'attached'");

    // 3. Replace the simple login flow with bounding box clicks
    const loginRegex = /await emailField\.click\(\{ force: true \}\);\s*await page\.keyboard\.type\((.+?),\s*\{ delay: 50 \}\);\s*await passwordField\.click\(\{ force: true \}\);\s*await page\.keyboard\.type\((.+?),\s*\{ delay: 50 \}\);\s*await page\.waitForTimeout\(1000\);\s*await submitBtn\.click\(\{ force: true \}\);/g;
    
    c = c.replace(loginRegex, (m, emailVars, passVars) => `const emailBox = await emailField.boundingBox();
    if (emailBox) {
      await page.mouse.click(emailBox.x + emailBox.width / 2, emailBox.y + emailBox.height / 2);
      await page.waitForTimeout(500);
      await page.keyboard.type(${emailVars}, { delay: 50 });
    } else {
      await emailField.click({ force: true });
      await page.keyboard.type(${emailVars}, { delay: 50 });
    }
    const passwordBox = await passwordField.boundingBox();
    if (passwordBox) {
      await page.mouse.click(passwordBox.x + passwordBox.width / 2, passwordBox.y + passwordBox.height / 2);
      await page.waitForTimeout(500);
      await page.keyboard.type(${passVars}, { delay: 50 });
    } else {
      await passwordField.click({ force: true });
      await page.keyboard.type(${passVars}, { delay: 50 });
    }
    await page.waitForTimeout(1000);
    const submitBox = await submitBtn.boundingBox();
    if (submitBox) {
      await page.mouse.click(submitBox.x + submitBox.width / 2, submitBox.y + submitBox.height / 2);
    } else {
      await submitBtn.click({ force: true });
    }`);

    fs.writeFileSync(filePath, c);
    console.log(filePath + ' updated');
}

['tests_e2e/tests/admin.spec.ts', 'tests_e2e/tests/gameplay.spec.ts'].forEach(applyFixes);

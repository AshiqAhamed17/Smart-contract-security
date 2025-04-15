
- Each vault works with one bridge
    ```javascript
    constructor(IERC20 _token) Ownable(msg.sender) {
        token = _token;
    }
    ```
// Dart Doc 文档增强脚本

(function() {
    'use strict';
    
    // 平滑滚动
    document.querySelectorAll('a[href^="#"]').forEach(anchor => {
        anchor.addEventListener('click', function(e) {
            const targetId = this.getAttribute('href').slice(1);
            const targetElement = document.getElementById(targetId);
            if (targetElement) {
                e.preventDefault();
                targetElement.scrollIntoView({
                    behavior: 'smooth',
                    block: 'start'
                });
            }
        });
    });
    
    // 为代码块添加复制按钮
    document.querySelectorAll('pre code').forEach(block => {
        const pre = block.parentElement;
        const button = document.createElement('button');
        button.className = 'copy-code-btn';
        button.textContent = '复制';
        button.style.cssText = `
            position: absolute;
            top: 8px;
            right: 8px;
            padding: 4px 12px;
            font-size: 12px;
            border: none;
            border-radius: 6px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            cursor: pointer;
            opacity: 0;
            transition: opacity 0.3s ease;
            z-index: 10;
        `;
        
        pre.style.position = 'relative';
        pre.appendChild(button);
        
        pre.addEventListener('mouseenter', () => {
            button.style.opacity = '1';
        });
        
        pre.addEventListener('mouseleave', () => {
            button.style.opacity = '0';
        });
        
        button.addEventListener('click', async () => {
            try {
                await navigator.clipboard.writeText(block.textContent);
                button.textContent = '已复制!';
                button.style.background = 'linear-gradient(135deg, #38a169 0%, #48bb78 100%)';
                setTimeout(() => {
                    button.textContent = '复制';
                    button.style.background = 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)';
                }, 2000);
            } catch (err) {
                button.textContent = '失败';
                setTimeout(() => {
                    button.textContent = '复制';
                }, 2000);
            }
        });
    });
    
    // 为侧边栏当前项添加高亮
    const currentPath = window.location.pathname;
    document.querySelectorAll('.sidebar a').forEach(link => {
        if (link.getAttribute('href') && currentPath.includes(link.getAttribute('href'))) {
            link.style.color = '#667eea';
            link.style.fontWeight = '700';
            link.parentElement.style.background = 'linear-gradient(135deg, rgba(102, 126, 234, 0.15) 0%, rgba(118, 75, 162, 0.15) 100%)';
            link.parentElement.style.borderRadius = '8px';
        }
    });
    
    // 添加返回顶部按钮
    const backToTop = document.createElement('button');
    backToTop.innerHTML = '↑';
    backToTop.className = 'back-to-top';
    backToTop.style.cssText = `
        position: fixed;
        bottom: 30px;
        right: 30px;
        width: 50px;
        height: 50px;
        border: none;
        border-radius: 50%;
        background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
        color: white;
        font-size: 24px;
        cursor: pointer;
        opacity: 0;
        visibility: hidden;
        transition: all 0.3s ease;
        box-shadow: 0 4px 15px rgba(102, 126, 234, 0.4);
        z-index: 1000;
    `;
    document.body.appendChild(backToTop);
    
    const mainContent = document.querySelector('.main-content');
    if (mainContent) {
        mainContent.addEventListener('scroll', () => {
            if (mainContent.scrollTop > 300) {
                backToTop.style.opacity = '1';
                backToTop.style.visibility = 'visible';
            } else {
                backToTop.style.opacity = '0';
                backToTop.style.visibility = 'hidden';
            }
        });
    }
    
    backToTop.addEventListener('click', () => {
        if (mainContent) {
            mainContent.scrollTo({
                top: 0,
                behavior: 'smooth'
            });
        }
    });
    
    backToTop.addEventListener('mouseenter', () => {
        backToTop.style.transform = 'scale(1.1)';
    });
    
    backToTop.addEventListener('mouseleave', () => {
        backToTop.style.transform = 'scale(1)';
    });
    
    // 为方法/属性添加锚点链接图标
    document.querySelectorAll('dt[id]').forEach(dt => {
        const id = dt.getAttribute('id');
        if (id) {
            const anchor = document.createElement('a');
            anchor.href = '#' + id;
            anchor.className = 'anchor-link';
            anchor.innerHTML = '#';
            anchor.style.cssText = `
                opacity: 0;
                margin-left: 8px;
                color: #667eea;
                text-decoration: none;
                font-weight: bold;
                transition: opacity 0.3s ease;
            `;
            
            dt.style.position = 'relative';
            dt.appendChild(anchor);
            
            dt.addEventListener('mouseenter', () => {
                anchor.style.opacity = '1';
            });
            
            dt.addEventListener('mouseleave', () => {
                anchor.style.opacity = '0';
            });
            
            anchor.addEventListener('click', (e) => {
                e.preventDefault();
                history.pushState(null, '', '#' + id);
                dt.scrollIntoView({ behavior: 'smooth', block: 'start' });
            });
        }
    });
    
    // 图片懒加载
    if ('IntersectionObserver' in window) {
        const imageObserver = new IntersectionObserver((entries, observer) => {
            entries.forEach(entry => {
                if (entry.isIntersecting) {
                    const img = entry.target;
                    if (img.dataset.src) {
                        img.src = img.dataset.src;
                        img.removeAttribute('data-src');
                    }
                    observer.unobserve(img);
                }
            });
        });
        
        document.querySelectorAll('img[data-src]').forEach(img => {
            imageObserver.observe(img);
        });
    }
    
    // 添加键盘快捷键支持
    document.addEventListener('keydown', (e) => {
        // Ctrl/Cmd + K 聚焦搜索框
        if ((e.ctrlKey || e.metaKey) && e.key === 'k') {
            e.preventDefault();
            const searchBox = document.getElementById('search-box') || document.getElementById('search-sidebar');
            if (searchBox) {
                searchBox.focus();
            }
        }
        
        // Escape 关闭搜索
        if (e.key === 'Escape') {
            const searchBox = document.getElementById('search-box') || document.getElementById('search-sidebar');
            if (searchBox && document.activeElement === searchBox) {
                searchBox.blur();
            }
        }
    });
    
    // 打印优化提示
    console.log('%c🎨 AtomicX Core 文档已优化', 'color: #667eea; font-size: 14px; font-weight: bold;');
    console.log('%c快捷键: Ctrl/Cmd + K 打开搜索', 'color: #764ba2; font-size: 12px;');
    
})();
